-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function () 
  hl.exec_cmd("waybar")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("udiskie")
  hl.exec_cmd("swaync")
  hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
end)

