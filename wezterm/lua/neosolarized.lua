local M = {}

local palette = {
	background = "#001217",
	foreground = "#708183",
	cursor_bg = "#708183",
	selection_bg = "#fcf4dc",
	selection_fg = "#001e26",
	tab_bar_background = "#073642",
	active_tab = {
		fg_color = "#181926",
		bg_color = "#268bd2",
	},
	inactive_tab = {
		fg_color = "#CAD3F5",
		bg_color = "#586e75",
	},
	ansi = {
		"#002b36",
		"#dc322f",
		"#859900",
		"#b58900",
		"#268bd2",
		"#d33682",
		"#2aa198",
		"#e9e2cb",
	},
	brights = {
		"#001e26",
		"#cb4b16",
		"#465a61",
		"#52676f",
		"#708183",
		"#6c71c4",
		"#81908f",
		"#fcf4dc",
	},
}

function M.colors()
	return {
		foreground = palette.foreground,
		background = palette.background,
		cursor_fg = palette.foreground,
		cursor_bg = palette.cursor_bg,
		cursor_border = palette.selection_fg,
		selection_bg = palette.selection_bg,
		selection_fg = palette.foreground,
		ansi = palette.ansi,
		brights = palette.brights,
		tab_bar = {
			background = palette.tab_bar_background,
			active_tab = {
				fg_color = palette.active_tab.fg_color,
				bg_color = palette.active_tab.bg_color,
			},
			inactive_tab = {
				fg_color = palette.inactive_tab.fg_color,
				bg_color = palette.inactive_tab.bg_color,
			},
			inactive_tab_hover = {
				fg_color = palette.active_tab.fg_color,
				bg_color = palette.active_tab.bg_color,
			},
			new_tab = {
				fg_color = palette.inactive_tab.fg_color,
				bg_color = palette.inactive_tab.bg_color,
			},
			new_tab_hover = {
				fg_color = palette.active_tab.fg_color,
				bg_color = palette.active_tab.bg_color,
			},
			inactive_tab_edge = palette.active_tab.fg_color,
		},
	}
end

function M.window_frame()
	return {
		active_titlebar_bg = palette.background,
		inactive_titlebar_bg = palette.background,
	}
end

return M
