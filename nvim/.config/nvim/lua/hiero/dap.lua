-- nvim-dap → Hiero panes. nvim-dap does the debugging; Hiero panes show it.
--
-- * output: most debug adapters (delve, netcoredbg, ...) send the program's
--   output as DAP `output` events. They go to a file that a pane next to this
--   nvim follows with `hiero pane follow` (Linux and Windows).
-- * panels (repl, ...): each is a small `nvim --clean -u hiero/start.lua` in its own pane that
--   talks to this nvim over RPC (see hiero/panel.lua). This nvim keeps the
--   session; a panel asks it to evaluate, and gets told when the program stops.
--
--   require("hiero.dap").setup({ dir = "down", size = 30 })
--
-- Outside Hiero (no $HIERO_PANE) it does nothing.

local M = {}

M.config = {
  cmd = "hiero", -- the hiero binary
  dir = "down", -- where the output pane opens next to this nvim: "down" or "right"
  size = 30, -- its share of the split, in percent
  focus = false, -- move the focus to it
  close_on_end = false, -- close the output pane when the session ends (otherwise it stays until the next run)
  categories = { stdout = true, stderr = true, console = false }, -- DAP output categories to show
  -- Panel panes opened with a session; {} for none. repl and watches go in a
  -- row beside the output pane; variables, stack and breakpoints in a column
  -- right of nvim, in the order given.
  panels = { "repl", "watches", "variables", "stack", "breakpoints" },
  close_panels_on_end = true, -- close the panels when the session ends
  column_size = 30, -- the column's width, in percent
}

local state = { file = nil, path = nil, pane = nil }

local function own_pane()
  local p = vim.env.HIERO_PANE
  return (p and p ~= "") and p or nil
end

-- One set of panes per nvim pane, so two nvims in a workspace don't share them.
local function pane_name(kind)
  return "dap " .. kind .. " " .. own_pane():sub(-4)
end

local function log_path()
  return vim.fn.stdpath("run") .. "/hiero-dap-" .. own_pane() .. ".log"
end

-- The panels start from start.lua, next to this file.
local start_file = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h") .. "/start.lua"

local function hiero(args, on_ok)
  local argv = vim.list_extend({ M.config.cmd, "pane" }, args)
  vim.system(argv, { text = true }, function(r)
    if r.code ~= 0 then
      vim.schedule(function()
        vim.notify("hiero pane: " .. vim.trim(r.stderr or ""), vim.log.levels.WARN)
      end)
    elseif on_ok then
      vim.schedule(function()
        on_ok(vim.trim(r.stdout or ""))
      end)
    end
  end)
end

local function write(s)
  if state.file then
    state.file:write(s)
    state.file:flush()
  end
end

-- Panels ---------------------------------------------------------------------

-- Connected panels by their server address: { chan, kind }.
local subs = {}

local function notify(addr, fn, ...)
  local sub = subs[addr]
  if not sub then
    return
  end
  local ok = pcall(vim.rpcnotify, sub.chan, "nvim_exec_lua", ("require('hiero.panel').%s(...)"):format(fn), { ... })
  if not ok then
    subs[addr] = nil
  end
end

local function broadcast(fn, ...)
  for addr in pairs(subs) do
    notify(addr, fn, ...)
  end
end

local function nilable(v)
  if v == nil then
    return vim.NIL
  end
  return v
end

local function err_text(err)
  if type(err) ~= "table" then
    return tostring(err)
  end
  local fmt = vim.tbl_get(err, "body", "error", "format")
  return fmt or err.message or vim.inspect(err)
end

local send_frame -- below

--- From a panel: it listens at `addr`. Connect back so we can tell it things.
function M._subscribe(kind, addr)
  local ok, chan = pcall(vim.fn.sockconnect, "pipe", addr, { rpc = true })
  if not ok or chan == 0 then
    return
  end
  subs[addr] = { chan = chan, kind = kind }
  local s = require("dap").session()
  notify(addr, "on_hello", s and (s.config.name or "debug") or vim.NIL)
  if kind == "watches" then
    send_watches(addr)
  elseif kind == "breakpoints" then
    send_bps(addr)
  end
  -- Already stopped: show it now.
  if s and s.stopped_thread_id and s.current_frame then
    s:request("scopes", { frameId = s.current_frame.id }, function(err, body)
      if not err then
        send_frame(s, body, addr)
      end
    end)
  end
end

--- From a panel: evaluate in the current frame and answer it.
function M._eval(addr, expr)
  local s = require("dap").session()
  if not s then
    notify(addr, "on_eval", expr, "no debug session", vim.NIL, vim.NIL)
    return
  end
  s:evaluate(expr, function(err, resp)
    notify(
      addr,
      "on_eval",
      expr,
      err and err_text(err) or vim.NIL,
      nilable(resp and resp.result),
      nilable(resp and resp.type)
    )
  end)
end

local function frame_list(session)
  local t = session.stopped_thread_id and session.threads[session.stopped_thread_id]
  local out = {}
  for _, f in ipairs(t and t.frames or {}) do
    local src = f.source and (f.source.path or f.source.name) or ""
    table.insert(out, { id = f.id, name = f.name or "?", file = vim.fn.fnamemodify(src, ":t"), line = f.line or 0 })
  end
  return out
end

local function scope_list(body)
  local out = {}
  for _, sc in ipairs(body and body.scopes or {}) do
    table.insert(out, { name = sc.name, ref = sc.variablesReference or 0, expensive = sc.expensive or false })
  end
  return out
end

--- Tell panels (one `addr`, or all) where the stopped program is: its frames,
--- the current frame and that frame's scopes.
send_frame = function(session, body, addr)
  local cur = session.current_frame
  local args = { frame_list(session), cur and cur.id or vim.NIL, scope_list(body) }
  if addr then
    notify(addr, "on_frame", unpack(args))
  else
    broadcast("on_frame", unpack(args))
  end
end

--- From a panel: make frame `id` of the stopped thread the current one (nvim jumps there).
function M._select_frame(_, id)
  local s = require("dap").session()
  if not s then
    return
  end
  for _, f in ipairs(s.stopped_thread_id and s.threads[s.stopped_thread_id].frames or {}) do
    if f.id == id then
      s:_frame_set(f)
      return
    end
  end
end

--- From a panel: the children of variables reference `ref`, answered with request `req`.
function M._variables(addr, req, ref)
  local s = require("dap").session()
  if not s then
    return
  end
  s:request("variables", { variablesReference = ref }, function(err, resp)
    local out = {}
    for _, v in ipairs(not err and resp and resp.variables or {}) do
      table.insert(out, { name = v.name, value = v.value or "", type = v.type or "", ref = v.variablesReference or 0 })
    end
    notify(addr, "on_variables", req, out, err and err_text(err) or vim.NIL)
  end)
end

-- Watches: kept here, so they outlive panels and sessions. Each entry is
-- re-evaluated on every stop and frame change.
local watches = {}

local function send_watches(addr)
  local s = require("dap").session()
  local results = {}
  local function done()
    if addr then
      notify(addr, "on_watches", results)
    else
      broadcast("on_watches", results)
    end
  end
  local stopped = s and s.stopped_thread_id and s.current_frame
  for i, e in ipairs(watches) do
    results[i] = { expr = e, value = "", type = "", err = "", stale = not stopped }
  end
  if #watches == 0 or not stopped then
    return done()
  end
  local left = #watches
  for i, e in ipairs(watches) do
    s:evaluate({ expression = e, context = "watch" }, function(err, resp)
      local r = results[i]
      r.value = resp and resp.result or ""
      r.type = resp and resp.type or ""
      r.err = err and err_text(err) or ""
      left = left - 1
      if left == 0 then
        done()
      end
    end)
  end
end

function M._watch_add(_, expr)
  table.insert(watches, expr)
  send_watches()
end

function M._watch_set(_, i, expr)
  if watches[i] then
    watches[i] = expr
    send_watches()
  end
end

function M._watch_del(_, i)
  table.remove(watches, i)
  send_watches()
end

-- Breakpoints: nvim-dap has no event for a toggle, so a breakpoints panel is
-- sent the list again whenever it changed (checked every second).
local function bp_list()
  local out = {}
  for buf, bps in pairs(require("dap.breakpoints").get()) do
    local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":~:.")
    for _, bp in ipairs(bps) do
      table.insert(out, {
        buf = buf,
        line = bp.line,
        file = file,
        cond = bp.condition or "",
        hit = bp.hitCondition or "",
        log = bp.logMessage or "",
      })
    end
  end
  table.sort(out, function(a, b)
    if a.file ~= b.file then
      return a.file < b.file
    end
    return a.line < b.line
  end)
  return out
end

local last_bps = nil

local function send_bps(addr)
  local list = bp_list()
  local key = vim.inspect(list)
  if addr then
    notify(addr, "on_breakpoints", list)
    return
  end
  if key ~= last_bps then
    last_bps = key
    for a, sub in pairs(subs) do
      if sub.kind == "breakpoints" then
        notify(a, "on_breakpoints", list)
      end
    end
  end
end

--- From a panel: show breakpoint `line` of buffer `buf` in this nvim.
function M._bp_jump(_, buf, line)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
  end
  vim.api.nvim_set_current_win(win)
  pcall(vim.api.nvim_win_set_cursor, win, { line, 0 })
  vim.cmd("normal! zz")
end

--- From a panel: remove a breakpoint, and tell the sessions.
function M._bp_delete(_, buf, line)
  local breakpoints = require("dap.breakpoints")
  breakpoints.remove(buf, line)
  local bps = breakpoints.get(buf)
  bps[buf] = bps[buf] or {}
  for _, s in pairs(require("dap").sessions()) do
    s:set_breakpoints(bps)
  end
  send_bps()
end

local function panel_args(kind, where)
  local args = { "split", "--reuse", "--name", pane_name(kind), "--no-focus" }
  vim.list_extend(args, where)
  vim.list_extend(args, { "--", vim.v.progpath, "--clean", "-u", start_file, "--", kind, vim.v.servername })
  return args
end

local ROW = { repl = true, watches = true }

--- Open the panels as a chain: each splits the one before it in `dir`, which
--- joins the same split, and `--size` is the new pane's share of that split.
--- So the n-th pane of the split takes 1/n and they all end up the same size.
--- `first` places the first one; `before` panes are already in its split.
local function chain(kinds, first, dir, before)
  local function step(i, prev)
    local kind = kinds[i]
    if not kind then
      return
    end
    local where = prev and { "--pane", prev, "--dir", dir, "--size", tostring(math.floor(100 / (before + i))) }
      or first()
    hiero(panel_args(kind, where), function(id)
      step(i + 1, id)
    end)
  end
  step(1, nil)
end

--- repl and watches sit beside the output pane (`beside`), sharing its row;
--- variables, stack and breakpoints share a column right of nvim.
local panels_open = false

local function open_panels(beside)
  panels_open = true
  local row, column = {}, {}
  for _, kind in ipairs(M.config.panels) do
    table.insert(ROW[kind] and row or column, kind)
  end
  -- The row joins the output pane's split (or starts one under nvim).
  chain(row, function()
    if beside then
      return { "--pane", beside, "--dir", "right", "--size", "50" }
    end
    return { "--dir", M.config.dir, "--size", tostring(M.config.size or 30) }
  end, "right", beside and 1 or 0)
  chain(column, function()
    return { "--dir", "right", "--size", tostring(M.config.column_size) }
  end, "down", 0)
end

local function close_panels()
  panels_open = false
  for _, kind in ipairs(M.config.panels) do
    hiero({ "close", "--name", pane_name(kind) })
  end
end

--- Open the panels, or close them when they are open (for a key like <F7>).
function M.toggle_panels()
  if not own_pane() then
    return
  end
  if panels_open then
    close_panels()
  else
    open_panels(state.pane)
  end
end

-- Output ---------------------------------------------------------------------

--- Start a fresh output file and open (or restart) the pane that follows it.
--- `then_` gets the pane's id.
function M.open(title, then_)
  if not own_pane() then
    return
  end
  if state.file then
    state.file:close()
  end
  state.path = log_path()
  state.file = io.open(state.path, "w")
  if not state.file then
    vim.notify("hiero.dap: can't write " .. state.path, vim.log.levels.WARN)
    return
  end
  write(("\27[2m── %s · %s ──\27[0m\n"):format(title or "debug", os.date("%H:%M:%S")))
  local args = { "split", "--reuse", "--name", pane_name("output"), "--dir", M.config.dir }
  if M.config.size then
    vim.list_extend(args, { "--size", tostring(M.config.size) })
  end
  if not M.config.focus then
    table.insert(args, "--no-focus")
  end
  vim.list_extend(args, { "--", M.config.cmd, "pane", "follow", state.path })
  hiero(args, function(id)
    state.pane = id
    if then_ then
      then_(id)
    end
  end)
end

--- Close the output pane.
function M.close()
  if own_pane() then
    hiero({ "close", "--name", pane_name("output") })
  end
  state.pane = nil
end

local function on_output(_, body)
  local cat = body.category or "console"
  if not M.config.categories[cat] or not body.output then
    return
  end
  if cat == "stderr" then
    write("\27[31m" .. body.output .. "\27[0m")
  elseif cat == "console" then
    write("\27[2m" .. body.output .. "\27[0m")
  else
    write(body.output)
  end
end

-- Session --------------------------------------------------------------------

local ended = false
local stop_pending = nil -- the reason of a stop whose location isn't known yet

local function on_end(_, body)
  if ended then
    return
  end
  ended = true
  local code = body and body.exitCode
  local text = code and ("exited with " .. code) or "session ended"
  write(("\27[2m── %s ──\27[0m\n"):format(text))
  broadcast("on_event", text)
  if M.config.close_on_end then
    M.close()
  end
  if M.config.close_panels_on_end then
    close_panels()
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  if not own_pane() then
    return
  end
  local dap = require("dap")
  local function start(session)
    ended = false
    M.open(session and session.config and session.config.name, function(out)
      open_panels(out)
    end)
  end
  dap.listeners.before.launch.hiero = start
  dap.listeners.before.attach.hiero = start
  dap.listeners.after.event_output.hiero = on_output
  dap.listeners.after.event_exited.hiero = on_end
  dap.listeners.after.event_terminated.hiero = on_end
  dap.listeners.after.event_stopped.hiero = function(_, body)
    stop_pending = body.reason or "stopped"
  end
  -- The stopped thread's frames arrive after the stop: that's where it is.
  dap.listeners.after.stackTrace.hiero = function(session, err, body, request)
    if not stop_pending or err or not body or request.threadId ~= session.stopped_thread_id then
      return
    end
    local f = (body.stackFrames or {})[1]
    local where = f and ("%s:%d"):format(f.source and (f.source.name or f.source.path) or f.name, f.line or 0) or ""
    broadcast("on_event", ("%s at %s"):format(stop_pending, where))
    stop_pending = nil
  end
  -- Scopes are fetched on every stop and every frame change (from a panel,
  -- or dap.up/down in nvim): the moment to show where the program is.
  dap.listeners.after.scopes.hiero = function(session, err, body)
    if not err and session.stopped_thread_id then
      send_frame(session, body)
      send_watches()
    end
  end
  local function running()
    broadcast("on_running")
  end
  for _, req in ipairs({ "continue", "next", "stepIn", "stepOut", "stepBack", "reverseContinue" }) do
    dap.listeners.after[req].hiero = running
  end
  dap.listeners.after.event_continued.hiero = running
  vim.uv.new_timer():start(1000, 1000, vim.schedule_wrap(function()
    if next(subs) then
      send_bps()
    end
  end))
  vim.api.nvim_create_user_command("HieroDapOutput", function()
    M.open("output")
  end, { desc = "Open the Hiero pane for debug output" })
  vim.api.nvim_create_user_command("HieroDapOutputClose", M.close, { desc = "Close the Hiero debug output pane" })
  vim.api.nvim_create_user_command("HieroDapPanels", function()
    open_panels(state.pane)
  end, { desc = "Open the Hiero debug panels" })
  vim.api.nvim_create_user_command("HieroDapPanelsClose", close_panels, { desc = "Close the Hiero debug panels" })
end

return M
