require("triforce").setup {
  enabled = true, -- Enable/disable the entire plugin
  gamification_enabled = true, -- Enable XP, levels, achievements

  -- Notification settings
  notifications = {
    enabled = true, -- Master toggle for all notifications
    level_up = true, -- Show level up notifications
    achievements = true, -- Show achievement unlock notifications
  },

  -- Keymap configuration
  keymap = {
    show_profile = "<leader>tp", -- Set to nil to disable default keymap
  },

  -- Auto-save interval (in seconds)
  auto_save_interval = 300, -- Save stats every 5 minutes

  -- Add custom language support
  custom_languages = {
    gleam = { icon = "✨", name = "Gleam" },
    odin = { icon = "🔷", name = "Odin" },
    -- Add more languages...
  },

  -- Customize level progression (optional)
  level_progression = {
    tier_1 = { min_level = 1, max_level = 10, xp_per_level = 500 },
    tier_2 = { min_level = 11, max_level = 20, xp_per_level = 750 },
    tier_3 = { min_level = 21, max_level = 30, xp_per_level = 1250 },
    tier_4 = { min_level = 31, max_level = 40, xp_per_level = 2500 },
    tier_5 = { min_level = 41, max_level = 50, xp_per_level = 3750 },
    tier_6 = { min_level = 51, max_level = 75, xp_per_level = 5000 },
    tier_7 = { min_level = 76, max_level = 100, xp_per_level = 10000 },
    tier_8 = { min_level = 101, max_level = 150, xp_per_level = 12500 },
    tier_9 = { min_level = 151, max_level = 225, xp_per_level = 15000 },
    tier_10 = { min_level = 226, max_level = math.huge, xp_per_level = 25000 },
  },

  -- Customize XP rewards (optional)
  xp_rewards = {
    char = 1, -- XP per character typed
    line = 1, -- XP per new line
    save = 50, -- XP per file save
  },
}
