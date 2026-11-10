local wezterm = require("wezterm")

local config = wezterm.config_builder()
local theme = wezterm.plugin.require("https://github.com/neapsix/wezterm").main
local act = wezterm.action

config.font_size = 10
config.colors = theme.colors()
config.window_frame = theme.window_frame()
config.enable_wayland = true
config.enable_tab_bar = true
config.tab_bar_at_bottom = true
config.harfbuzz_features = { "calt = 0", "clig = 0", "liga = 0" }

config.unix_domains = {
	{
		name = "unix",
	},
}

config.default_gui_startup_args = { "connect", "unix" }

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	{
		key = "\\",
		mods = "LEADER",
		action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "|",
		mods = "LEADER|SHIFT",
		action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "t",
		mods = "LEADER",
		action = act.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "s",
		mods = "LEADER",
		action = act.ShowLauncherArgs({ flags = "WORKSPACES" }),
	},

	{
		key = "w",
		mods = "LEADER",
		action = act.CloseCurrentTab({ confirm = true }),
	},
	{
		key = "x",
		mods = "LEADER",
		action = act.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "[",
		mods = "LEADER",
		action = act.ActivateTabRelative(-1),
	},
	{
		key = "]",
		mods = "LEADER",
		action = act.ActivateTabRelative(1),
	},
	{
		key = "h",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Left"),
	},
	{
		key = "j",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Down"),
	},
	{
		key = "k",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Up"),
	},
	{
		key = "l",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Right"),
	},
}

return config
