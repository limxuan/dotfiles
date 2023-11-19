local wezterm = require("wezterm")
local rose_pine_color = require("lua.custom-theme").colors()
local rose_pine_window_frame = require("lua.custom-theme").window_frame()

local fontFamily = "JetBrains Mono"
local fontWeight = "Medium"

return {
	font = wezterm.font_with_fallback({
		{
			family = fontFamily,
			weight = fontWeight,
		},
		{
			family = "Symbols Nerd Font Mono",
			scale = 0.7,
		},
	}),
	font_rules = {
		{
			-- italic
			intensity = "Normal",
			italic = true,
			font = wezterm.font({
				family = fontFamily,
				weight = fontWeight,
				italic = false,
			}),
		},
		{
			-- bold
			intensity = "Bold",
			italic = false,
			font = wezterm.font({
				family = fontFamily,
				weight = fontWeight,
			}),
		},
		{
			-- italic bold
			intensity = "Bold",
			italic = true,
			font = wezterm.font({
				family = fontFamily,
				weight = fontWeight,
				italic = false,
			}),
		},
	},
	font_size = 12.5,
	--
	hide_tab_bar_if_only_one_tab = true,
	use_fancy_tab_bar = false,
	initial_rows = 35,
	initial_cols = 120,
	window_padding = {
		top = 0,
		right = 0,
		bottom = 0,
		left = 0,
	},
	colors = rose_pine_color,
	window_frame = rose_pine_window_frame,
	window_decorations = "RESIZE",
	window_background_opacity = 0.9,
	macos_window_background_blur = 30,
	default_cwd = "/Documents/dev",
}
