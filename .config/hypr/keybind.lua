local scrPath = (os.getenv("HOME") or "") .. "/.config/hypr/Scripts"

local mainMod = "SUPER"

local TERMINAL = "kitty"
local EDITOR = "code"
local EXPLORER = "thunar"
local BROWSER = scrPath .. "/browser-launcher.sh"
local WORKSPACE = scrPath .. "/workspace.sh"
local SATTY = scrPath .. "/satty.sh"

local KEY = {
	-- Applications
	TERMINAL = ("%s + RETURN"):format(mainMod),
	EXPLORER = ("%s + E"):format(mainMod),
	EDITOR = ("%s + C"):format(mainMod),
	BROWSER = ("%s + B"):format(mainMod),

	-- Noctalia
	HELP = ("%s + H"):format(mainMod),
	LAUNCHER = ("%s + D"):format(mainMod),
	SETTINGS = ("%s + SHIFT + E"):format(mainMod),
	NOTIFICATIONS = ("%s + SHIFT + N"):format(mainMod),

	CLIPBOARD = ("%s + ALT + V"):format(mainMod),
	CLIP_HISTORY = ("%s + V"):format(mainMod),
	WINDOW_OVERVIEW = ("%s + A"):format(mainMod),
	EXPO = ("%s + O"):format(mainMod),

	WALLPAPER = ("%s + W"):format(mainMod),
	WALLPAPER_NEXT = ("%s + SHIFT + W"):format(mainMod),
	WALLPAPER_RANDOM = ("%s + CTRL + ALT + W"):format(mainMod),

	BAR_TOGGLE = ("%s + CTRL + ALT + B"):format(mainMod),

	-- Window management
	CLOSE = ("%s + Q"):format(mainMod),
	FORCE_CLOSE = ("%s + SHIFT + Q"):format(mainMod),

	FLOAT = ("%s + SPACE"):format(mainMod),
	ALL_FLOAT = ("%s + ALT + SPACE"):format(mainMod),

	GROUP = ("%s + G"):format(mainMod),
	FULLSCREEN = ("%s + SHIFT + F"):format(mainMod),

	BLUR = ("%s + ALT + O"):format(mainMod),
	OPAQUE = ("%s + CTRL + O"):format(mainMod),

	GAMEMODE = ("%s + SHIFT + G"):format(mainMod),

	LAYOUT = ("%s + ALT + L"):format(mainMod),
	TOGGLE_SPLIT = ("%s + SHIFT + I"):format(mainMod),

	-- Session
	EXIT = "CTRL + ALT + DELETE",
	LOGOUT = "CTRL + ALT + P",
	LOCK = "CTRL + ALT + L",

	-- Search / cheatsheet
	KEYBINDS = ("%s + SHIFT + K"):format(mainMod),
	SEARCH = ("%s + S"):format(mainMod),

	-- Workspaces
	WORKSPACE_NEXT = ("%s + TAB"):format(mainMod),
	WORKSPACE_PREV = ("%s + SHIFT + TAB"):format(mainMod),

	SPECIAL = ("%s + U"):format(mainMod),
	MOVE_SPECIAL = ("%s + SHIFT + U"):format(mainMod),

	-- Navigation
	FOCUS_LEFT = ("%s + left"):format(mainMod),
	FOCUS_RIGHT = ("%s + right"):format(mainMod),
	FOCUS_UP = ("%s + up"):format(mainMod),
	FOCUS_DOWN = ("%s + down"):format(mainMod),

	-- Resize
	RESIZE_RIGHT = ("%s + SHIFT + right"):format(mainMod),
	RESIZE_LEFT = ("%s + SHIFT + left"):format(mainMod),
	RESIZE_UP = ("%s + SHIFT + up"):format(mainMod),
	RESIZE_DOWN = ("%s + SHIFT + down"):format(mainMod),

	-- Move
	MOVE_RIGHT = ("%s + CTRL + right"):format(mainMod),
	MOVE_LEFT = ("%s + CTRL + left"):format(mainMod),
	MOVE_UP = ("%s + CTRL + up"):format(mainMod),
	MOVE_DOWN = ("%s + CTRL + down"):format(mainMod),

	-- Mouse
	MOUSE_MOVE = ("%s + mouse:272"):format(mainMod),
	MOUSE_RESIZE = ("%s + mouse:273"):format(mainMod),

	-- Zoom
	ZOOM_IN = ("%s + ALT + mouse_down"):format(mainMod),
	ZOOM_OUT = ("%s + ALT + mouse_up"):format(mainMod),
}

----------------------------------------------------------------------
-- 1. Applications
----------------------------------------------------------------------

hl.bind(KEY.TERMINAL, hl.dsp.exec_cmd(TERMINAL), {
	description = "Terminal",
})

hl.bind(KEY.EXPLORER, hl.dsp.exec_cmd(EXPLORER), {
	description = "File manager",
})

hl.bind(KEY.EDITOR, hl.dsp.exec_cmd(EDITOR), {
	description = "Code editor",
})

hl.bind(KEY.BROWSER, hl.dsp.exec_cmd(BROWSER), {
	description = "Browser",
})

----------------------------------------------------------------------
-- 2. Noctalia
----------------------------------------------------------------------

-- Help / cheatsheet
hl.bind(
	KEY.HELP,
	hl.dsp.exec_cmd("noctalia msg panel-toggle kenn/keybind-cheatsheet:cheatsheet"),
	{ description = "Help / keybind cheatsheet" }
)

-- Application launcher
hl.bind(
	KEY.LAUNCHER,
	hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"),
	{ description = "Application launcher" }
)

-- Settings
hl.bind(
	KEY.SETTINGS,
	hl.dsp.exec_cmd("noctalia msg settings-toggle"),
	{ description = "Hyprland / Noctalia settings" }
)

-- Notifications
hl.bind(
	KEY.NOTIFICATIONS,
	hl.dsp.exec_cmd("noctalia msg panel-toggle control-center notifications"),
	{ description = "Notification panel" }
)

-- Clipboard
hl.bind(
	KEY.CLIPBOARD,
	hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"),
	{ description = "Clipboard manager" }
)

-- Clipboard history (persistent, via cliphist)
hl.bind(
	KEY.CLIP_HISTORY,
	hl.dsp.exec_cmd("cliphist list | wofi --dmenu --prompt 'Clipboard history' | cliphist decode | wl-copy"),
	{ description = "Clipboard history" }
)

-- Window overview
hl.bind(
	KEY.WINDOW_OVERVIEW,
	hl.dsp.exec_cmd("noctalia msg window-switcher"),
	{ description = "Window overview" }
)

-- Workspace overview (hyprexpo)
hl.bind(
	KEY.EXPO,
	function()
		hl.plugin.hyprexpo.expo("toggle")
	end,
	{ description = "Workspace overview" }
)

-- Wallpaper
hl.bind(
	KEY.WALLPAPER,
	hl.dsp.exec_cmd("noctalia msg panel-toggle wallpaper"),
	{ description = "Wallpaper menu" }
)

hl.bind(
	KEY.WALLPAPER_NEXT,
	hl.dsp.exec_cmd("noctalia msg wallpaper-next"),
	{ description = "Next wallpaper" }
)

hl.bind(
	KEY.WALLPAPER_RANDOM,
	hl.dsp.exec_cmd("noctalia msg wallpaper-random"),
	{ description = "Random wallpaper" }
)

-- Toggle Noctalia bar
hl.bind(
	KEY.BAR_TOGGLE,
	hl.dsp.exec_cmd("noctalia msg bar-toggle"),
	{ description = "Toggle bar" }
)

----------------------------------------------------------------------
-- 3. Session
----------------------------------------------------------------------

hl.bind(
	KEY.EXIT,
	hl.dsp.exec_cmd("hyprctl dispatch exit"),
	{ description = "Exit Hyprland" }
)

hl.bind(
	KEY.LOGOUT,
	hl.dsp.exec_cmd("noctalia msg panel-toggle session"),
	{ description = "Logout / session menu" }
)

hl.bind(
	KEY.LOCK,
	hl.dsp.exec_cmd("noctalia msg session lock"),
	{ description = "Lock screen" }
)

----------------------------------------------------------------------
-- 4. Window management
----------------------------------------------------------------------

-- Toggle current window floating
hl.bind(
	KEY.FLOAT,
	hl.dsp.window.float({ action = "toggle" }),
	{ description = "Toggle floating" }
)

-- Toggle ALL windows floating on current workspace
hl.bind(
	KEY.ALL_FLOAT,
	hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allfloat"),
	{ description = "Toggle all windows floating" }
)

-- Toggle group
hl.bind(
	KEY.GROUP,
	hl.dsp.exec_cmd("hyprctl dispatch togglegroup"),
	{ description = "Toggle group" }
)

-- Fullscreen
hl.bind(
	KEY.FULLSCREEN,
	hl.dsp.window.fullscreen(),
	{ description = "Toggle fullscreen" }
)

-- Close active window
hl.bind(
	KEY.CLOSE,
	hl.dsp.window.close(),
	{ description = "Close window" }
)

-- Force kill active window
hl.bind(
	KEY.FORCE_CLOSE,
	hl.dsp.exec_cmd("hyprctl dispatch forcekillactive"),
	{ description = "Force kill window" }
)

----------------------------------------------------------------------
-- 5. Focus
----------------------------------------------------------------------

hl.bind(
	KEY.FOCUS_LEFT,
	hl.dsp.focus({ direction = "left" }),
	{ description = "Focus left" }
)

hl.bind(
	KEY.FOCUS_RIGHT,
	hl.dsp.focus({ direction = "right" }),
	{ description = "Focus right" }
)

hl.bind(
	KEY.FOCUS_UP,
	hl.dsp.focus({ direction = "up" }),
	{ description = "Focus up" }
)

hl.bind(
	KEY.FOCUS_DOWN,
	hl.dsp.focus({ direction = "down" }),
	{ description = "Focus down" }
)

-- Traditional Alt+Tab
hl.bind(
	"ALT + tab",
	hl.dsp.exec_cmd("noctalia msg window-switcher"),
	{ description = "Window switcher" }
)

----------------------------------------------------------------------
-- 6. Resize windows
----------------------------------------------------------------------

hl.bind(
	KEY.RESIZE_RIGHT,
	function()
		hl.exec_cmd("hyprctl dispatch resizeactive 30 0")
	end,
	{ description = "Resize right" }
)

hl.bind(
	KEY.RESIZE_LEFT,
	function()
		hl.exec_cmd("hyprctl dispatch resizeactive -30 0")
	end,
	{ description = "Resize left" }
)

hl.bind(
	KEY.RESIZE_UP,
	function()
		hl.exec_cmd("hyprctl dispatch resizeactive 0 -30")
	end,
	{ description = "Resize up" }
)

hl.bind(
	KEY.RESIZE_DOWN,
	function()
		hl.exec_cmd("hyprctl dispatch resizeactive 0 30")
	end,
	{ description = "Resize down" }
)

----------------------------------------------------------------------
-- 7. Move windows
----------------------------------------------------------------------

hl.bind(
	KEY.MOVE_LEFT,
	hl.dsp.window.move({ direction = "left" }),
	{ description = "Move window left" }
)

hl.bind(
	KEY.MOVE_RIGHT,
	hl.dsp.window.move({ direction = "right" }),
	{ description = "Move window right" }
)

hl.bind(
	KEY.MOVE_UP,
	hl.dsp.window.move({ direction = "up" }),
	{ description = "Move window up" }
)

hl.bind(
	KEY.MOVE_DOWN,
	hl.dsp.window.move({ direction = "down" }),
	{ description = "Move window down" }
)

----------------------------------------------------------------------
-- 8. Layout
----------------------------------------------------------------------

-- Toggle Dwindle / Master
hl.bind(
	KEY.LAYOUT,
	function()
		hl.exec_cmd([[
			if [ "$(hyprctl getoption general:layout | awk 'NR==1 {print $2}')" = "dwindle" ]; then
				hyprctl keyword general:layout master
			else
				hyprctl keyword general:layout dwindle
			fi
		]])
	end,
	{ description = "Toggle Dwindle / Master" }
)

-- Toggle Dwindle split
hl.bind(
	KEY.TOGGLE_SPLIT,
	hl.dsp.exec_cmd("hyprctl dispatch layoutmsg togglesplit"),
	{ description = "Toggle split" }
)

----------------------------------------------------------------------
-- 9. Blur
----------------------------------------------------------------------

hl.bind(
	KEY.BLUR,
	function()
		hl.exec_cmd([[
			current=$(hyprctl getoption decoration:blur:enabled | awk 'NR==1 {print $2}')
			if [ "$current" = "true" ]; then
				hyprctl keyword decoration:blur:enabled false
			else
				hyprctl keyword decoration:blur:enabled true
			fi
		]])
	end,
	{ description = "Toggle blur" }
)

----------------------------------------------------------------------
-- 10. Opacity
----------------------------------------------------------------------

hl.bind(
	KEY.OPAQUE,
	hl.dsp.exec_cmd("hyprctl dispatch setprop active opaque toggle"),
	{ description = "Toggle opaque / opacity" }
)

----------------------------------------------------------------------
-- 11. Gamemode
----------------------------------------------------------------------

hl.bind(
	KEY.GAMEMODE,
	hl.dsp.exec_cmd("~/.config/hypr/gamemode.sh"),
	{ description = "Toggle gamemode" }
)

----------------------------------------------------------------------
-- 12. Zoom
----------------------------------------------------------------------

local function zoom_in()
	hl.exec_cmd([[
		hyprctl -q keyword cursor:zoom_factor \
		$(hyprctl getoption cursor:zoom_factor -j | jq '.float * 1.1')
	]])
end

local function zoom_out()
	hl.exec_cmd([[
		hyprctl -q keyword cursor:zoom_factor \
		$(hyprctl getoption cursor:zoom_factor -j | jq '(.float * 0.9) | if . < 1 then 1 else . end')
	]])
end

hl.bind(
	KEY.ZOOM_IN,
	zoom_in,
	{ mouse = true, description = "Zoom in" }
)

hl.bind(
	KEY.ZOOM_OUT,
	zoom_out,
	{ mouse = true, description = "Zoom out" }
)

----------------------------------------------------------------------
-- 13. Workspace switching
----------------------------------------------------------------------

for i = 1, 9 do
	local focusKey = ("%s + %d"):format(mainMod, i)

	hl.bind(
		focusKey,
		hl.dsp.focus({ workspace = i }),
		{ description = "Workspace " .. i }
	)
end

hl.bind(
	("%s + 0"):format(mainMod),
	hl.dsp.focus({ workspace = 10 }),
	{ description = "Workspace 10" }
)

----------------------------------------------------------------------
-- 14. Workspace +1 / -1
----------------------------------------------------------------------

hl.bind(
	KEY.WORKSPACE_NEXT,
	hl.dsp.focus({ workspace = "e+1" }),
	{ description = "Next workspace" }
)

hl.bind(
	KEY.WORKSPACE_PREV,
	hl.dsp.focus({ workspace = "e-1" }),
	{ description = "Previous workspace" }
)

----------------------------------------------------------------------
-- 15. Special workspace
----------------------------------------------------------------------

hl.bind(
	KEY.SPECIAL,
	hl.dsp.exec_cmd("hyprctl dispatch togglespecialworkspace"),
	{ description = "Toggle special workspace" }
)

hl.bind(
	KEY.MOVE_SPECIAL,
	hl.dsp.window.move({ workspace = "special" }),
	{ description = "Move window to special workspace" }
)

----------------------------------------------------------------------
-- 16. Mouse window management
----------------------------------------------------------------------

hl.bind(
	KEY.MOUSE_MOVE,
	hl.dsp.window.drag(),
	{
		mouse = true,
		description = "Move floating window",
	}
)

hl.bind(
	KEY.MOUSE_RESIZE,
	hl.dsp.window.resize(),
	{
		mouse = true,
		description = "Resize floating window",
	}
)

----------------------------------------------------------------------
-- 17. Screenshots
----------------------------------------------------------------------

-- Super + Print = monitor
hl.bind(
	"SUPER + PRINT",
	hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && HYPRSHOT_DIR=~/Pictures/Screenshots hyprshot -m output"),
	{ description = "Screenshot monitor" }
)

-- Super + Shift + Print = region
hl.bind(
	"SUPER + SHIFT + PRINT",
	hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && HYPRSHOT_DIR=~/Pictures/Screenshots hyprshot -m region"),
	{ description = "Screenshot region" }
)

-- Super + Shift + S = screenshot + Satty
hl.bind(
	"SUPER + SHIFT + S",
	hl.dsp.exec_cmd(SATTY),
	{ description = "Screenshot and annotate" }
)

-- Super + Ctrl + Print = 5 second timer
hl.bind(
	"SUPER + CTRL + PRINT",
	hl.dsp.exec_cmd("sleep 5 && mkdir -p ~/Pictures/Screenshots && HYPRSHOT_DIR=~/Pictures/Screenshots hyprshot -m output"),
	{ description = "Screenshot monitor after 5 seconds" }
)

-- Super + Ctrl + Shift + Print = 10 second timer
hl.bind(
	"SUPER + CTRL + SHIFT + PRINT",
	hl.dsp.exec_cmd("sleep 10 && mkdir -p ~/Pictures/Screenshots && HYPRSHOT_DIR=~/Pictures/Screenshots hyprshot -m output"),
	{ description = "Screenshot monitor after 10 seconds" }
)

-- Alt + Print = active window
hl.bind(
	"ALT + PRINT",
	hl.dsp.exec_cmd("mkdir -p ~/Pictures/Screenshots && HYPRSHOT_DIR=~/Pictures/Screenshots hyprshot -m window"),
	{ description = "Screenshot active window" }
)

----------------------------------------------------------------------
-- 18. Media
----------------------------------------------------------------------

hl.bind(
	"XF86AudioPlay",
	hl.dsp.exec_cmd("noctalia msg media toggle"),
	{ locked = true, description = "Play / pause" }
)

hl.bind(
	"XF86AudioNext",
	hl.dsp.exec_cmd("noctalia msg media next"),
	{ locked = true, description = "Next track" }
)

hl.bind(
	"XF86AudioPrev",
	hl.dsp.exec_cmd("noctalia msg media previous"),
	{ locked = true, description = "Previous track" }
)

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("noctalia msg volume-up 5%"),
	{ locked = true, description = "Volume up" }
)

hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("noctalia msg volume-down 5%"),
	{ locked = true, description = "Volume down" }
)

hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("noctalia msg volume-mute"),
	{ locked = true, description = "Mute" }
)

hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("brightnessctl set 5%+"),
	{ locked = true, repeating = true, description = "Brightness up" }
)

hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("brightnessctl set 5%-"),
	{ locked = true, repeating = true, description = "Brightness down" }
)

----------------------------------------------------------------------
-- 19. Search
----------------------------------------------------------------------

-- Noctalia launcher is used as the modern replacement for the old Rofi
-- search stack.
hl.bind(
	KEY.SEARCH,
	hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"),
	{ description = "Search / launcher" }
)

----------------------------------------------------------------------
-- 20. Keybind cheatsheet
----------------------------------------------------------------------

hl.bind(
	KEY.KEYBINDS,
	hl.dsp.exec_cmd("noctalia msg panel-toggle kenn/keybind-cheatsheet:cheatsheet"),
	{ description = "Searchable keybindings" }
)

return true
