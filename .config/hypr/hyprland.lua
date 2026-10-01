local config_dir = (os.getenv("HOME") or "") .. "/.config/hypr"
package.path = table.concat({
    config_dir .. "/?.lua",
    config_dir .. "/?/init.lua",
    package.path,
}, ";")

-- Clear cached modules so they re-execute on reload (ensures binds/rules re-register)
for _, mod in ipairs({"monitors", "inputs", "keybind", "windowrules", "animations", "themes.theme"}) do
    package.loaded[mod] = nil
end

require("monitors")
require("startup")
require("inputs")
require("keybind")
require("windowrules")
require("animations")
require("themes.theme")

-- Load plugins declared in config so they exist before hl.config parses plugin.* keys.
-- handlePluginLoads() loads these after the first pass and re-runs reload() with errors cleared.
hl.plugin.load("/var/cache/hyprpm/" .. (os.getenv("USER") or "") .. "/hyprexpo/hyprexpo.so")

hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        anr_missed_pings = 5,
        allow_session_lock_restore = true,
    },
    xwayland = {
        force_zero_scaling = true,
    },
    general = {
        snap = {
            enabled = true,
        },
    },
    plugin = {
        hyprexpo = {
            columns = 3,
            workspace_method = "center current",
        },
    },
})

-- For Noctalia Color templates
require("noctalia").apply_theme()
