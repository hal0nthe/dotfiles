--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Tags
-- settings
hl.window_rule( { match =  { title = "wiremix"},                    tag = "+settings" } )
hl.window_rule( { match =  { title = "btop ~"},                    tag = "+settings" } )
hl.window_rule( { match =  { class = "nwg-look"},                    tag = "+settings" } )
hl.window_rule( { match =  { class = "org.pulseaudio.pavucontrol"}, tag = "+settings" } )
-- filemanager
hl.window_rule( { match =  { class = "thunar"},                    tag = "+filemanager" } )
-- image viewer
hl.window_rule( { match =  { class = "Nsxiv"},                      tag = "+imageviewer"})
hl.window_rule( { match =  { class = "sxiv"},                      tag = "+imageviewer"})
hl.window_rule( { match =  { class = "feh"},                      tag = "+imageviewer"})
hl.window_rule( { match =  { class = "swayimg"},                      tag = "+imageviewer"})
hl.window_rule( { match =  { class = "imv"},                      tag = "+imageviewer"})

-- Window
hl.window_rule( {match = { tag = "settings" }, float = true})
hl.window_rule( {match = { tag = "imageviewer" }, float = true})
hl.window_rule( {match = { tag = "filemanager" }, float = true})
hl.window_rule( {match = { class = "term-popup" }, float = true})

-- Size
hl.window_rule( {match = { tag = "settings" }, size = {"(monitor_w*0.7)","(monitor_h*0.7)"}})
-- hl.window_rule( {match = { tag = "imageviewer" }, size = {"(monitor_w*0.7)","(monitor_h*0.7)"}})
hl.window_rule( {match = { tag = "filemanager" }, size = {"(monitor_w*0.6)","(monitor_h*0.8)"}})
hl.window_rule( {match = { class = "term-popup" }, size = {"(monitor_w*0.6)","(monitor_h*0.8)"}})

-- Center
hl.window_rule( {match = { tag = "settings" }, center = true})
hl.window_rule( {match = { tag = "filemanager" }, center = true})
hl.window_rule( {match = { tag = "imageviewer" }, center = true})
hl.window_rule( {match = { class = "term-popup" }, center = true})

-- Layer
-- rofi
hl.layer_rule( {match = { namespace = "rofi" }, blur = true})
-- wlogout
hl.layer_rule( {match = { namespace = "logout_dialog" }, blur = true})
-- notification
hl.layer_rule( {match = { namespace = "swaync-control-center" }, blur = true})
hl.layer_rule( {match = { namespace = "swaync-control-center" }, ignore_alpha = 0.5})
hl.layer_rule( {match = { namespace = "swaync-notification-window" }, blur = true})
hl.layer_rule( {match = { namespace = "swaync-notification-window" }, ignore_alpha = 0.5})

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
