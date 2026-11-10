-- A panel pane: a small nvim that talks to the main nvim (which holds the
-- nvim-dap session) over RPC. The main side is hiero/dap.lua.
--
-- Panel → main: require('hiero.dap')._subscribe / _eval / _select_frame /
-- _variables / _watch_* / _bp_*, by rpcnotify.
-- Main → panel: require('hiero.panel').on_hello / on_eval / on_event /
-- on_frame / on_running / on_variables / on_watches / on_breakpoints, by rpcnotify over a channel the main
-- nvim opens to this panel's server. Nothing blocks on the other side, so a
-- busy nvim never freezes the other.
--
-- Kinds: repl, stack, variables, watches, breakpoints.

local M = {}

local S = { kind = nil, server = nil, chan = nil, buf = nil, said_down = false }
local ns = vim.api.nvim_create_namespace("hiero_panel")
local view = {} -- the handlers of this panel's kind

local function present(v)
  return v ~= nil and v ~= vim.NIL
end

--- Call the main nvim. False when it can't be reached.
local function call(fn, ...)
  if not S.chan then
    return false
  end
  local ok = pcall(vim.rpcnotify, S.chan, "nvim_exec_lua", ("require('hiero.dap').%s(...)"):format(fn), { ... })
  if not ok then
    S.chan = nil
  end
  return ok
end

local function one_line(s)
  return (tostring(s):gsub("\r?\n", "⏎"))
end

-- A read-only view: replace all lines; `marks` are {line, col, opts} extmarks.
local function show(lines, marks)
  local buf = S.buf
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, m in ipairs(marks or {}) do
    pcall(vim.api.nvim_buf_set_extmark, buf, ns, m[1], m[2], m[3])
  end
end

local function cursor_line()
  return vim.api.nvim_win_get_cursor(0)[1]
end

local function set_cursor_line(n)
  n = math.max(1, math.min(n, vim.api.nvim_buf_line_count(S.buf)))
  pcall(vim.api.nvim_win_set_cursor, 0, { n, 0 })
end

local function scratch()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "hide"
  vim.api.nvim_set_current_buf(buf)
  vim.wo.wrap = false
  vim.wo.cursorline = true
  return buf
end

-- REPL -----------------------------------------------------------------------

local repl = { history = {}, hist_i = nil }

--- Add lines above the prompt, highlighted with `hl`, the last one with a dim `note` after it.
local function append(text, hl, note)
  local buf = S.buf
  if S.kind ~= "repl" then
    return
  end
  local lines = vim.split(text, "\n", { plain = true })
  local at = vim.api.nvim_buf_line_count(buf) - 1
  vim.api.nvim_buf_set_lines(buf, at, at, false, lines)
  for i = 0, #lines - 1 do
    if hl then
      vim.api.nvim_buf_set_extmark(buf, ns, at + i, 0, { line_hl_group = hl })
    end
  end
  if note then
    vim.api.nvim_buf_set_extmark(buf, ns, at + #lines - 1, 0, { virt_text = { { "  " .. note, "Comment" } } })
  end
  -- Keep the prompt line in view in every window showing it.
  for _, w in ipairs(vim.fn.win_findbuf(buf)) do
    vim.api.nvim_win_call(w, function()
      vim.cmd("normal! zb")
    end)
  end
end

local function set_prompt_text(text)
  local n = vim.api.nvim_buf_line_count(S.buf)
  local line = vim.fn.prompt_getprompt(S.buf) .. text
  vim.api.nvim_buf_set_lines(S.buf, n - 1, n, false, { line })
  vim.api.nvim_win_set_cursor(0, { n, #line })
end

local function history(step)
  local h = repl.history
  if #h == 0 then
    return
  end
  local i = (repl.hist_i or #h + 1) + step
  if i < 1 then
    i = 1
  end
  if i > #h then
    repl.hist_i = nil
    set_prompt_text("")
    return
  end
  repl.hist_i = i
  set_prompt_text(h[i])
end

function repl.start()
  local buf = vim.api.nvim_create_buf(false, true)
  S.buf = buf
  vim.bo[buf].buftype = "prompt"
  vim.fn.prompt_setprompt(buf, "> ")
  vim.fn.prompt_setcallback(buf, function(text)
    text = vim.trim(text)
    if text == "" then
      return
    end
    if repl.history[#repl.history] ~= text then
      table.insert(repl.history, text)
    end
    repl.hist_i = nil
    if not call("_eval", vim.v.servername, text) then
      append("not connected to nvim", "ErrorMsg")
    end
  end)
  vim.fn.prompt_setinterrupt(buf, function() end)
  vim.keymap.set("i", "<Up>", function()
    history(-1)
  end, { buffer = buf })
  vim.keymap.set("i", "<Down>", function()
    history(1)
  end, { buffer = buf })
  vim.api.nvim_set_current_buf(buf)
  vim.cmd.startinsert()
end

function repl.status(text, hl)
  append(text, hl or "Comment")
end

function repl.on_eval(_, err, result, typ)
  if present(err) then
    append(err, "ErrorMsg")
  else
    append(present(result) and result or "", nil, present(typ) and typ ~= "" and typ or nil)
  end
end

function repl.on_event(text)
  append("● " .. text, "Comment")
end

-- Stack ----------------------------------------------------------------------

local stack = { frames = {}, current = nil, note = "no debug session" }

local function render_stack()
  if #stack.frames == 0 then
    show({ stack.note }, { { 0, 0, { line_hl_group = "Comment" } } })
    return
  end
  local lines, marks = {}, {}
  local width = 0
  for _, f in ipairs(stack.frames) do
    width = math.max(width, vim.fn.strdisplaywidth(f.name))
  end
  for i, f in ipairs(stack.frames) do
    local cur = f.id == stack.current
    local name = f.name .. string.rep(" ", width - vim.fn.strdisplaywidth(f.name))
    lines[i] = ("%s %s  %s:%d"):format(cur and "▶" or " ", name, f.file, f.line)
    local where = #lines[i] - #(("%s:%d"):format(f.file, f.line))
    table.insert(marks, { i - 1, where, { end_col = #lines[i], hl_group = "Comment" } })
    if cur then
      table.insert(marks, { i - 1, 0, { end_col = #"▶", hl_group = "Special" } })
    end
  end
  if stack.note then
    table.insert(lines, 1, stack.note)
    for _, m in ipairs(marks) do
      m[1] = m[1] + 1
    end
    table.insert(marks, { 0, 0, { line_hl_group = "Comment" } })
  end
  show(lines, marks)
end

local function stack_frame_at_cursor()
  local i = cursor_line() - (stack.note and 1 or 0)
  return stack.frames[i]
end

function stack.start()
  S.buf = scratch()
  render_stack()
  local function select()
    local f = stack_frame_at_cursor()
    if f then
      call("_select_frame", vim.v.servername, f.id)
    end
  end
  vim.keymap.set("n", "<CR>", select, { buffer = S.buf })
  vim.keymap.set("n", "<2-LeftMouse>", select, { buffer = S.buf })
end

function stack.status(text)
  stack.frames, stack.note = {}, text
  render_stack()
end

function stack.on_frame(frames, current)
  local had = #stack.frames > 0
  stack.frames, stack.current, stack.note = frames, current, nil
  render_stack()
  -- On a new stop, put the cursor on the current frame.
  if not had then
    for i, f in ipairs(frames) do
      if f.id == current then
        set_cursor_line(i)
      end
    end
  end
end

function stack.on_running()
  stack.note = "● running"
  render_stack()
end

function stack.on_event(text)
  stack.status("● " .. text)
end

-- Variables ------------------------------------------------------------------

-- A node: { name, value, type, ref, path, depth, children = nil|{...}, scope = bool }.
-- `open` remembers expanded paths across stops; `closed` the scopes you folded.
local vars = { roots = {}, open = {}, closed = {}, gen = 0, pending = {}, next_req = 0, lines = {}, note = "no debug session" }

local function request_children(node)
  vars.next_req = vars.next_req + 1
  vars.pending[vars.next_req] = { node = node, gen = vars.gen }
  call("_variables", vim.v.servername, vars.next_req, node.ref)
end

local function is_open(node)
  if node.scope then
    return not vars.closed[node.path]
  end
  return vars.open[node.path] == true
end

local function render_vars()
  local at = vars.lines[cursor_line()]
  local keep = at and at.path
  local lines, marks, map = {}, {}, {}
  if vars.note then
    table.insert(lines, vars.note)
    table.insert(marks, { 0, 0, { line_hl_group = "Comment" } })
    map[#lines] = false
  end
  local function walk(node)
    local indent = string.rep("  ", node.depth)
    local marker = node.ref > 0 and (is_open(node) and "▾ " or "▸ ") or "  "
    local text
    if node.scope then
      text = indent .. marker .. node.name
    else
      text = indent .. marker .. node.name .. " = " .. one_line(node.value)
    end
    table.insert(lines, text)
    map[#lines] = node
    local row = #lines - 1
    if node.scope then
      table.insert(marks, { row, #indent + #marker, { end_col = #text, hl_group = "Title" } })
    else
      table.insert(marks, { row, #indent + #marker, { end_col = #indent + #marker + #node.name, hl_group = "Identifier" } })
      if node.type ~= "" then
        table.insert(marks, { row, 0, { virt_text = { { "  " .. node.type, "Comment" } } } })
      end
    end
    if node.ref > 0 and is_open(node) then
      if node.children == nil then
        table.insert(lines, indent .. "    …")
        map[#lines] = false
      else
        for _, c in ipairs(node.children) do
          walk(c)
        end
      end
    end
  end
  for _, r in ipairs(vars.roots) do
    walk(r)
  end
  if #lines == 0 then
    lines = { "no variables" }
  end
  vars.lines = map
  show(lines, marks)
  if keep then
    for i, n in pairs(map) do
      if n and n.path == keep then
        set_cursor_line(i)
        break
      end
    end
  end
end

local function expand(node)
  if node.scope then
    vars.closed[node.path] = nil
  else
    vars.open[node.path] = true
  end
  if node.children == nil then
    request_children(node)
  end
  render_vars()
end

local function collapse(node)
  if node.scope then
    vars.closed[node.path] = true
  else
    vars.open[node.path] = nil
  end
  render_vars()
end

local function parent_line(node)
  for i = cursor_line() - 1, 1, -1 do
    local n = vars.lines[i]
    if n and n.depth < node.depth then
      return i
    end
  end
end

function vars.start()
  S.buf = scratch()
  render_vars()
  local function at()
    return vars.lines[cursor_line()]
  end
  local function toggle()
    local n = at()
    if n and n.ref > 0 then
      if is_open(n) then
        collapse(n)
      else
        expand(n)
      end
    end
  end
  vim.keymap.set("n", "<CR>", toggle, { buffer = S.buf })
  vim.keymap.set("n", "<2-LeftMouse>", toggle, { buffer = S.buf })
  vim.keymap.set("n", "l", function()
    local n = at()
    if n and n.ref > 0 and not is_open(n) then
      expand(n)
    end
  end, { buffer = S.buf })
  vim.keymap.set("n", "h", function()
    local n = at()
    if not n then
      return
    end
    if n.ref > 0 and is_open(n) then
      collapse(n)
    else
      local p = parent_line(n)
      if p then
        set_cursor_line(p)
      end
    end
  end, { buffer = S.buf })
end

function vars.status(text)
  vars.roots, vars.note = {}, text
  render_vars()
end

function vars.on_frame(_, _, scopes)
  -- A new stop or frame: start over, and open again what was open.
  vars.gen = vars.gen + 1
  vars.pending = {}
  vars.note = nil
  vars.roots = {}
  for _, sc in ipairs(scopes) do
    local node = { name = sc.name, value = "", type = "", ref = sc.ref, path = sc.name, depth = 0, scope = true }
    -- Expensive scopes (globals, registers) start folded.
    if sc.expensive and vars.closed[node.path] == nil then
      vars.closed[node.path] = true
    end
    table.insert(vars.roots, node)
    if node.ref > 0 and is_open(node) then
      request_children(node)
    end
  end
  render_vars()
end

function vars.on_variables(req, list, err)
  local p = vars.pending[req]
  vars.pending[req] = nil
  if not p or p.gen ~= vars.gen then
    return
  end
  local node = p.node
  node.children = {}
  if present(err) then
    table.insert(node.children, { name = "error", value = err, type = "", ref = 0, path = node.path .. "/!", depth = node.depth + 1 })
  end
  for _, v in ipairs(list) do
    -- delve names the target of a pointer "": show it as "*".
    local name = v.name ~= "" and v.name or "*"
    local c = { name = name, value = v.value, type = v.type, ref = v.ref, path = node.path .. "/" .. name, depth = node.depth + 1 }
    table.insert(node.children, c)
    if c.ref > 0 and is_open(c) then
      request_children(c)
    end
  end
  render_vars()
end

function vars.on_running()
  vars.note = "● running"
  render_vars()
end

function vars.on_event(text)
  vars.status("● " .. text)
end

-- Watches --------------------------------------------------------------------

local watchv = { list = {}, note = nil }

local function render_watches()
  local lines, marks = {}, {}
  for i, w in ipairs(watchv.list) do
    local text
    if w.err ~= "" then
      text = w.expr .. ": " .. one_line(w.err)
      table.insert(marks, { i - 1, #w.expr, { end_col = #text, hl_group = "ErrorMsg" } })
    elseif w.stale then
      text = w.expr .. " = " .. (w.value ~= "" and one_line(w.value) or "…")
      table.insert(marks, { i - 1, #w.expr, { end_col = #text, hl_group = "Comment" } })
    else
      text = w.expr .. " = " .. one_line(w.value)
      if w.type ~= "" then
        table.insert(marks, { i - 1, 0, { virt_text = { { "  " .. w.type, "Comment" } } } })
      end
    end
    table.insert(marks, { i - 1, 0, { end_col = #w.expr, hl_group = "Identifier" } })
    lines[i] = text
  end
  local hint = #lines == 0 and "no watches · a adds one" or "a add · e edit · d delete"
  table.insert(lines, (watchv.note and (watchv.note .. " · ") or "") .. hint)
  table.insert(marks, { #lines - 1, 0, { line_hl_group = "Comment" } })
  show(lines, marks)
end

function watchv.start()
  S.buf = scratch()
  render_watches()
  local function at()
    local i = cursor_line()
    return watchv.list[i] and i or nil
  end
  local function add()
    vim.ui.input({ prompt = "watchv: " }, function(text)
      if text and vim.trim(text) ~= "" then
        call("_watch_add", vim.v.servername, vim.trim(text))
      end
    end)
  end
  local function edit()
    local i = at()
    if not i then
      return add()
    end
    vim.ui.input({ prompt = "watchv: ", default = watchv.list[i].expr }, function(text)
      if text and vim.trim(text) ~= "" then
        call("_watch_set", vim.v.servername, i, vim.trim(text))
      end
    end)
  end
  vim.keymap.set("n", "a", add, { buffer = S.buf })
  vim.keymap.set("n", "e", edit, { buffer = S.buf })
  vim.keymap.set("n", "<CR>", edit, { buffer = S.buf })
  vim.keymap.set("n", "d", function()
    local i = at()
    if i then
      call("_watch_del", vim.v.servername, i)
    end
  end, { buffer = S.buf })
end

function watchv.status(text)
  watchv.note = text
  render_watches()
end

function watchv.on_watches(list)
  watchv.list, watchv.note = list, nil
  render_watches()
end

function watchv.on_running()
  for _, w in ipairs(watchv.list) do
    w.stale = true
  end
  watchv.note = "● running"
  render_watches()
end

function watchv.on_event(text)
  watchv.on_running()
  watchv.note = "● " .. text
  render_watches()
end

-- Breakpoints ----------------------------------------------------------------

local bps = { list = {}, note = nil }

local function render_bps()
  local lines, marks = {}, {}
  for i, b in ipairs(bps.list) do
    local where = ("%s:%d"):format(b.file, b.line)
    local extra = {}
    if b.cond ~= "" then
      table.insert(extra, "if " .. b.cond)
    end
    if b.hit ~= "" then
      table.insert(extra, "hit " .. b.hit)
    end
    if b.log ~= "" then
      table.insert(extra, "log " .. b.log)
    end
    lines[i] = "● " .. where .. (#extra > 0 and ("  " .. table.concat(extra, " · ")) or "")
    table.insert(marks, { i - 1, 0, { end_col = #"●", hl_group = "ErrorMsg" } })
    table.insert(marks, { i - 1, #"● " + #where, { end_col = #lines[i], hl_group = "Comment" } })
  end
  local hint = #lines == 0 and "no breakpoints" or "Enter go to · d delete"
  table.insert(lines, (bps.note and (bps.note .. " · ") or "") .. hint)
  table.insert(marks, { #lines - 1, 0, { line_hl_group = "Comment" } })
  show(lines, marks)
end

function bps.start()
  S.buf = scratch()
  render_bps()
  local function at()
    return bps.list[cursor_line()]
  end
  local function go()
    local b = at()
    if b then
      call("_bp_jump", vim.v.servername, b.buf, b.line)
    end
  end
  vim.keymap.set("n", "<CR>", go, { buffer = S.buf })
  vim.keymap.set("n", "<2-LeftMouse>", go, { buffer = S.buf })
  vim.keymap.set("n", "d", function()
    local b = at()
    if b then
      call("_bp_delete", vim.v.servername, b.buf, b.line)
    end
  end, { buffer = S.buf })
end

function bps.status(text)
  bps.note = text
  render_bps()
end

function bps.on_breakpoints(list)
  bps.list, bps.note = list, nil
  render_bps()
end

-- Connection -----------------------------------------------------------------

local function status(text, hl)
  if view.status then
    view.status(text, hl)
  end
end

local function connect()
  local ok, chan = pcall(vim.fn.sockconnect, "pipe", S.server, { rpc = true })
  if ok and chan > 0 then
    S.chan = chan
    S.said_down = false
    call("_subscribe", S.kind, vim.v.servername)
  elseif not S.said_down then
    S.said_down = true
    status("waiting for nvim at " .. S.server)
  end
end

local function watch()
  local timer = vim.uv.new_timer()
  timer:start(0, 1000, vim.schedule_wrap(function()
    -- A closed channel has no info left.
    if S.chan and next(vim.api.nvim_get_chan_info(S.chan)) == nil then
      S.chan = nil
      status("lost the connection to nvim")
    end
    if not S.chan then
      connect()
    end
  end))
end

-- From the main nvim: each goes to this panel's view, if it cares.

local function dispatch(name)
  return function(...)
    local f = view[name]
    if f then
      f(...)
    end
  end
end

function M.on_hello(session)
  if S.kind == "repl" then
    append(present(session) and ("connected · " .. session) or "connected · no debug session", "Comment")
  elseif not present(session) then
    status("no debug session")
  end
end

M.on_eval = dispatch("on_eval")
M.on_event = dispatch("on_event")
M.on_frame = dispatch("on_frame")
M.on_running = dispatch("on_running")
M.on_variables = dispatch("on_variables")
M.on_watches = dispatch("on_watches")
M.on_breakpoints = dispatch("on_breakpoints")

-- Start ----------------------------------------------------------------------

local kinds = { repl = repl, stack = stack, variables = vars, watches = watchv, breakpoints = bps }

function M.start(kind, server)
  S.kind, S.server = kind or "repl", server
  vim.o.shadafile = "NONE"
  vim.o.swapfile = false
  vim.o.number = false
  vim.o.signcolumn = "no"
  vim.o.laststatus = 0
  vim.o.ruler = false
  vim.o.showmode = false
  vim.o.termguicolors = true
  vim.opt.shortmess:append("I")
  view = kinds[S.kind]
  if not view then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hiero panel: unknown kind " .. tostring(kind) })
    return
  end
  view.start()
  if not server or server == "" then
    status("no nvim server given", "ErrorMsg")
    return
  end
  watch()
end

return M
