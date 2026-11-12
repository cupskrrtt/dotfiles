-- C# debugging driven by Visual Studio's Properties/launchSettings.json.
--
-- F5 in a .cs buffer lists the launch profiles of the project that file
-- belongs to (or, for a class library, of every runnable project under the
-- cwd). After you pick one, before the debugger starts:
--   1. any running instance of that app (e.g. `dotnet run --no-build`) is killed,
--   2. only that project is built (incremental; errors go to the quickfix list),
--   3. it starts with the profile's env vars and args:
--      - "Project" profiles: launched directly under netcoredbg (Kestrel).
--      - "IISExpress" profiles (Windows only): IIS Express is started with a
--        generated applicationhost.config, warmed up with one request so the
--        app loads, then netcoredbg attaches to it. Code that runs at startup
--        (Program.cs) has already run by then, so breakpoints there won't hit.

local M = {}

local is_win = vim.fn.has("win32") == 1
local SKIP_DIRS = { bin = true, obj = true, node_modules = true, [".git"] = true, [".vs"] = true }

-- Coroutine helpers so the steps below read top to bottom without blocking the UI.
local function system(cmd)
	local co = coroutine.running()
	vim.system(cmd, { text = true }, function(r)
		vim.schedule(function()
			coroutine.resume(co, r)
		end)
	end)
	return coroutine.yield()
end

local function sleep(ms)
	local co = coroutine.running()
	vim.defer_fn(function()
		coroutine.resume(co)
	end, ms)
	coroutine.yield()
end

local function notify(msg, level)
	vim.notify(msg, level or vim.log.levels.INFO, { title = "dotnet debug" })
end

local function read_file(path)
	local f = io.open(path, "rb")
	if not f then
		return nil
	end
	local text = f:read("*a")
	f:close()
	return text
end

local function read_json(path)
	local text = read_file(path)
	if not text then
		return nil
	end
	-- Visual Studio often saves with a UTF-8 BOM, which the JSON parser rejects.
	local ok, data = pcall(vim.json.decode, (text:gsub("^\239\187\191", "")))
	return ok and data or nil
end

-- "a b \"c d\"" -> { "a", "b", "c d" }
local function split_args(str)
	local args, cur, in_quote = {}, {}, false
	for ch in (str or ""):gmatch(".") do
		if ch == '"' then
			in_quote = not in_quote
		elseif ch:match("%s") and not in_quote then
			if #cur > 0 then
				args[#args + 1] = table.concat(cur)
				cur = {}
			end
		else
			cur[#cur + 1] = ch
		end
	end
	if #cur > 0 then
		args[#args + 1] = table.concat(cur)
	end
	return args
end

-- ---------------------------------------------------------------------------
-- Processes (Linux: pgrep/kill, Windows: PowerShell/taskkill)
-- ---------------------------------------------------------------------------

-- PIDs of processes whose command line contains `needle`.
local function find_pids(needle)
	local r
	if is_win then
		local quoted = "'" .. needle:gsub("'", "''") .. "'"
		r = system({
			"powershell",
			"-NoProfile",
			"-Command",
			"Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -and $_.CommandLine.Contains("
				.. quoted
				.. ") } | ForEach-Object { $_.ProcessId }",
		})
	else
		r = system({ "pgrep", "-f", "--", vim.fn.escape(needle, [[\.^$*+?()[]{}|]]) })
	end
	return vim.split(vim.trim((r.stdout or ""):gsub("\r", "")), "\n", { trimempty = true })
end

local function kill_pids(pids, force)
	if is_win then
		local cmd = { "taskkill", "/T", "/F" } -- console apps ignore a polite close
		for _, pid in ipairs(pids) do
			vim.list_extend(cmd, { "/PID", pid })
		end
		system(cmd)
	else
		system(vim.list_extend({ "kill", force and "-KILL" or "-TERM" }, vim.deepcopy(pids)))
	end
end

-- Stop every process whose command line contains `needle`.
local function stop_matching(needle, label)
	local pids = find_pids(needle)
	if #pids == 0 then
		return
	end
	notify(("Stopping running %s (pid %s)"):format(label, table.concat(pids, ", ")))
	kill_pids(pids, false)
	for _ = 1, 20 do -- up to 2s for a graceful shutdown
		sleep(100)
		if #find_pids(needle) == 0 then
			return
		end
	end
	kill_pids(pids, true)
end

-- ---------------------------------------------------------------------------
-- IIS Express (Windows)
-- ---------------------------------------------------------------------------

local function xml_escape(s)
	return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

local function win_path(p)
	return (p:gsub("/", "\\"))
end

local function iis_express_dir()
	for _, var in ipairs({ "ProgramFiles", "ProgramFiles(x86)" }) do
		local base = vim.env[var]
		if base and vim.uv.fs_stat(base .. "\\IIS Express\\iisexpress.exe") then
			return base .. "\\IIS Express"
		end
	end
end

-- Write a private applicationhost.config for this site (what Visual Studio
-- keeps in .vs/<sln>/config, but under nvim's cache so neither the repo nor
-- VS's copy is touched). Returns its path, or nil + error.
local function write_iis_config(iis_dir, site, iis)
	local template = read_file(iis_dir .. "\\config\\templates\\PersonalWebServer\\applicationhost.config")
	if not template then
		return nil, "IIS Express config template not found in " .. iis_dir
	end
	if not template:find("AspNetCoreModuleV2", 1, true) then
		return nil, "ASP.NET Core Module V2 isn't registered with IIS Express (install the .NET Hosting Bundle)"
	end

	local bindings = { ('<binding protocol="http" bindingInformation="*:%d:localhost" />'):format(iis.port) }
	if iis.ssl_port and iis.ssl_port > 0 then
		bindings[2] = ('<binding protocol="https" bindingInformation="*:%d:localhost" />'):format(iis.ssl_port)
	end
	local site_xml = ([[
      <site name="%s" id="1000">
        <application path="/" applicationPool="Clr4IntegratedAppPool">
          <virtualDirectory path="/" physicalPath="%s" />
        </application>
        <bindings>
          %s
        </bindings>
      </site>
]]):format(xml_escape(site), xml_escape(win_path(iis.dir)), table.concat(bindings, "\n          "))

	-- Same handler block VS adds: ANCM runs whatever LAUNCHER_PATH points at.
	local location_xml = ([[
  <location path="%s">
    <system.webServer>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath="%%LAUNCHER_PATH%%" arguments="%%LAUNCHER_ARGS%%" stdoutLogEnabled="false" hostingModel="InProcess" />
      <security>
        <authentication>
          <windowsAuthentication enabled="%s" />
          <anonymousAuthentication enabled="%s" />
        </authentication>
      </security>
    </system.webServer>
  </location>
]]):format(xml_escape(site), tostring(iis.windows_auth), tostring(iis.anonymous_auth))

	local config, n1 = template:gsub("</sites>", function()
		return site_xml .. "    </sites>"
	end, 1)
	local n2
	config, n2 = config:gsub("</configuration>%s*$", function()
		return location_xml .. "</configuration>\n"
	end, 1)
	if n1 ~= 1 or n2 ~= 1 then
		return nil, "Unexpected IIS Express config template layout"
	end

	local dir = vim.fs.joinpath(vim.fn.stdpath("cache"), "dotnet_debug", site)
	vim.fn.mkdir(dir, "p")
	local path = win_path(vim.fs.joinpath(dir, "applicationhost.config"))
	local f = assert(io.open(path, "wb"))
	f:write(config)
	f:close()
	return path
end

M._iis_job = nil -- the IIS Express we started; stopped when the session ends

local function stop_iis_job()
	if M._iis_job and not M._iis_job:is_closing() then
		M._iis_job:kill(9)
	end
	M._iis_job = nil
end

-- Start IIS Express for the site, warm it up, return the PID to attach to.
local function start_iis(config, target)
	local iis_dir = iis_express_dir()
	if not iis_dir then
		return nil, "IIS Express isn't installed"
	end
	local site = vim.fn.fnamemodify(config.csproj, ":t:r")
	local cfg_path, err = write_iis_config(iis_dir, site, config.iis)
	if not cfg_path then
		return nil, err
	end
	stop_matching(cfg_path, "IIS Express for " .. site)

	-- In-process hosting: the app runs inside iisexpress.exe, started by ANCM
	-- from LAUNCHER_PATH. Profile env vars reach the app through this process.
	local exe = target:gsub("%.dll$", ".exe")
	local env = vim.tbl_extend("force", config.env or {}, {
		LAUNCHER_PATH = vim.uv.fs_stat(exe) and exe or "dotnet",
		LAUNCHER_ARGS = vim.uv.fs_stat(exe) and (config.iis.args or "") or ('"' .. target .. '" ' .. (config.iis.args or "")),
	})

	notify("Starting IIS Express for " .. site .. "…")
	local ok, job = pcall(vim.system, {
		iis_dir .. "\\iisexpress.exe",
		"/config:" .. cfg_path,
		"/site:" .. site,
		"/systray:false",
	}, { env = env, text = true })
	if not ok then
		return nil, "Couldn't start IIS Express: " .. tostring(job)
	end
	M._iis_job = job

	-- ANCM only loads the app on the first request; wait until IIS answers.
	-- --negotiate -u : sends your Windows credentials for windowsAuthentication sites.
	local url = ("http://localhost:%d/"):format(config.iis.port)
	for _ = 1, 120 do -- up to ~60s
		local r = system({ "curl", "-s", "-o", "NUL", "-w", "%{http_code}", "--negotiate", "-u", ":", url })
		local code = tonumber(r.stdout) or 0
		if code > 0 then
			sleep(500)
			return job.pid
		end
		if job:is_closing() then
			return nil, "IIS Express exited during startup (port in use?)"
		end
		sleep(500)
	end
	stop_iis_job()
	return nil, "IIS Express didn't respond on " .. url
end

-- ---------------------------------------------------------------------------
-- Building the F5 menu
-- ---------------------------------------------------------------------------

local function csproj_in(dir)
	return vim.fn.glob(dir .. "/*.csproj", false, true)[1]
end

-- One dap configuration per runnable profile of a csproj.
local function configs_for(csproj)
	local dir = vim.fs.dirname(csproj)
	local name = vim.fn.fnamemodify(csproj, ":t:r")
	local settings = read_json(dir .. "/Properties/launchSettings.json") or {}
	local iis_settings = settings.iisSettings or {}
	local configs = {}

	for profile_name, p in pairs(settings.profiles or {}) do
		local base = {
			type = "coreclr",
			request = "launch",
			name = name .. ": " .. profile_name,
			csproj = csproj, -- read by M.enrich
			cwd = p.workingDirectory or dir,
			env = vim.deepcopy(p.environmentVariables or {}),
		}
		if p.commandName == "Project" then
			if p.applicationUrl and not base.env.ASPNETCORE_URLS then
				base.env.ASPNETCORE_URLS = p.applicationUrl
			end
			base.args = split_args(p.commandLineArgs)
			configs[#configs + 1] = base
		elseif p.commandName == "IISExpress" and is_win then
			local express = iis_settings.iisExpress or {}
			local port = tonumber((express.applicationUrl or ""):match(":(%d+)"))
			if port then
				base.name = base.name .. " (IIS Express)"
				base.iis = {
					dir = dir,
					port = port,
					ssl_port = tonumber(express.sslPort),
					windows_auth = iis_settings.windowsAuthentication == true,
					anonymous_auth = iis_settings.anonymousAuthentication ~= false,
					args = p.commandLineArgs,
				}
				configs[#configs + 1] = base
			end
		end
	end
	table.sort(configs, function(a, b)
		return a.name < b.name
	end)
	return configs
end

-- Every csproj under `root` that has a launchSettings.json (skipping bin/obj/...).
local function runnable_projects(root)
	local found = {}
	for path, kind in
		vim.fs.dir(root, {
			depth = 6,
			skip = function(dir)
				return not SKIP_DIRS[vim.fs.basename(dir)]
			end,
		})
	do
		path = vim.fs.normalize(path)
		if kind == "file" and vim.fs.basename(path) == "launchSettings.json" and path:match("Properties/[^/]+$") then
			local csproj = csproj_in(vim.fs.dirname(vim.fs.dirname(vim.fs.joinpath(root, path))))
			if csproj then
				found[#found + 1] = csproj
			end
		end
	end
	return found
end

-- nvim-dap config provider: builds the F5 menu for the current buffer.
local function provider(bufnr)
	if vim.bo[bufnr].filetype ~= "cs" then
		return {}
	end
	local file = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))
	local csproj_path = vim.fs.find(function(name)
		return name:match("%.csproj$")
	end, { upward = true, path = vim.fs.dirname(file), type = "file" })[1]

	-- The file's own project, if it is runnable.
	if csproj_path then
		local own = configs_for(csproj_path)
		if #own > 0 then
			return own
		end
	end

	-- A library (or no project): offer every runnable project under the cwd.
	local all = {}
	for _, csproj in ipairs(runnable_projects(vim.fs.normalize(vim.fn.getcwd()))) do
		vim.list_extend(all, configs_for(csproj))
	end
	if #all == 0 and csproj_path then
		-- Runnable project without launchSettings.json: plain launch.
		all[1] = {
			type = "coreclr",
			request = "launch",
			name = vim.fn.fnamemodify(csproj_path, ":t:r"),
			csproj = csproj_path,
			cwd = vim.fs.dirname(csproj_path),
		}
	end
	return all
end

-- ---------------------------------------------------------------------------
-- Adapter hook: runs after a profile is picked, before netcoredbg starts
-- ---------------------------------------------------------------------------

function M.enrich(config, on_config)
	if not config.csproj then
		return on_config(config)
	end
	coroutine.wrap(function()
		local csproj = config.csproj
		local name = vim.fn.fnamemodify(csproj, ":t:r")

		local prop = system({ "dotnet", "msbuild", csproj, "-getProperty:TargetPath", "-p:Configuration=Debug" })
		local target = vim.trim((prop.stdout or ""):gsub("\r", ""))
		if prop.code ~= 0 or target == "" then
			return notify("Couldn't resolve output path for " .. name, vim.log.levels.ERROR)
		end

		-- The app itself (apphost `…/Api[.exe]` or `dotnet …/Api.dll`).
		stop_matching(target:gsub("%.dll$", ""), name)

		notify("Building " .. name .. "…")
		local build = system({ "dotnet", "build", csproj, "-c", "Debug", "--nologo", "-v", "q", "-clp:NoSummary" })
		if build.code ~= 0 then
			vim.fn.setqflist({}, " ", {
				title = "dotnet build " .. name,
				lines = vim.split((build.stdout or ""):gsub("\r", ""), "\n"),
				efm = [[%f(%l\,%c): %trror %m,%f(%l\,%c): %tarning %m,%-G%.%#]],
			})
			return notify("Build failed: " .. name .. " (see :copen)", vim.log.levels.ERROR)
		end

		local final = { type = "coreclr", name = config.name }
		if config.iis then
			local pid, err = start_iis(config, target)
			if not pid then
				return notify(err, vim.log.levels.ERROR)
			end
			final.request = "attach"
			final.processId = pid
		else
			final.request = "launch"
			final.program = target
			final.cwd = config.cwd
			final.args = config.args
			final.env = config.env
		end
		on_config(final)
	end)()
end

function M.setup()
	local dap = require("dap")
	dap.providers.configs["dotnet.launchSettings"] = provider
	-- Ending the session (F4, or the app exiting) also stops our IIS Express.
	for _, event in ipairs({ "event_terminated", "event_exited", "disconnect" }) do
		dap.listeners.after[event].dotnet_debug = stop_iis_job
	end
end

return M
