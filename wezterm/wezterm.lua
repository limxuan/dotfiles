local wezterm = require("wezterm")
local rose_pine_color = require("lua.rose-pine").colors()
local rose_pine_window_frame = require("lua.rose-pine").window_frame()

local config = {}

-- colorscheme
config.colors = rose_pine_color
config.window_frame = rose_pine_window_frame
config.window_background_opacity = 0.9
config.text_background_opacity = 0
config.macos_window_background_blur = 30
config.window_decorations = "RESIZE"
config.window_padding = {
	top = 0,
	bottom = 0,
	left = 10,
	right = 0,
}
config.hide_tab_bar_if_only_one_tab = true

config.font = wezterm.font("JetBrains Mono")

return config
