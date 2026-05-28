-- matugen.lua
-- Reads ~/.config/matugen/themes/code-colors.jsonc at startup and on SIGUSR1
-- Applies a full Material You colorscheme to Neovim

local M = {}

local JSON_PATH = vim.fn.expand("~/.config/nvim/colors/code-colors.jsonc")

-- ---------------------------------------------------------------------------
-- Strip // line comments and /* block comments */ from JSONC
-- ---------------------------------------------------------------------------
local function strip_jsonc(str)
  -- Remove /* ... */ block comments (including multiline)
  str = str:gsub("/%*.-%*/", "")
  -- Remove // line comments, but not inside strings
  -- Simple approach: skip // that are preceded by a colon+space (URLs like https://)
  str = str:gsub('([^:])//[^\n]*', '%1')
  return str
end

-- ---------------------------------------------------------------------------
-- JSON parser (tiny, dependency-free)
-- ---------------------------------------------------------------------------
local function parse_json(str)
  local ok, result = pcall(vim.fn.json_decode, str)
  if not ok then
    vim.notify("matugen: failed to parse JSON", vim.log.levels.ERROR)
    return nil
  end
  return result
end

-- ---------------------------------------------------------------------------
-- Load colors from JSONC
-- ---------------------------------------------------------------------------
local function load_colors()
  local f = io.open(JSON_PATH, "r")
  if not f then
    vim.notify("matugen: cannot open " .. JSON_PATH, vim.log.levels.ERROR)
    return nil
  end
  local raw = f:read("*a")
  f:close()

  local data = parse_json(strip_jsonc(raw))
  if not data then return nil end

  local w = data["workbench.colorCustomizations"]
  if not w then
    vim.notify("matugen: unexpected JSON structure", vim.log.levels.ERROR)
    return nil
  end

  -- Strip alpha from 8-char hex → 6-char hex for vim highlight fg/bg
  -- Also expose raw 8-char values for special cases
  local function hex(key)
    local v = w[key]
    if not v then return nil end
    -- 9-char (#RRGGBBAA) → take first 7 (#RRGGBB)
    if #v == 9 then return v:sub(1, 7) end
    return v
  end

  -- Build a clean color table mirroring M3 roles
  return {
    -- Core surfaces
    surface                  = hex("editor.background"),               -- #121318
    surface_low              = hex("sideBar.background"),              -- #1b1b21
    surface_container        = hex("statusBar.background"),            -- #1f1f25
    surface_high             = hex("sideBarSectionHeader.background"), -- #292a2f
    surface_highest          = hex("terminal.inactiveSelectionBackground"), -- #34343a

    -- Text
    on_surface               = hex("editor.foreground"),               -- #e3e1e9
    on_surface_variant       = hex("statusBar.foreground"),            -- #c6c5d0
    outline                  = hex("editorLineNumber.foreground"),     -- #90909a
    outline_variant          = hex("editorWidget.border"),             -- #46464f

    -- Primary (periwinkle blue)
    primary                  = hex("editorLineNumber.activeForeground"), -- #b9c3ff
    on_primary               = hex("button.foreground"),               -- #212c61
    primary_container        = hex("editorSuggestWidget.selectedBackground"), -- #384379
    on_primary_container     = hex("editorSuggestWidget.selectedForeground"), -- #dee1ff

    -- Secondary (cool grey-blue)
    secondary                = hex("editorWidget.border") ~= hex("editorWarning.foreground")
                               and hex("editorWarning.foreground") or "#c3c5dd", -- #c3c5dd
    secondary_container      = hex("statusBarItem.remoteBackground"),  -- #434659
    on_secondary_container   = hex("statusBarItem.remoteForeground"),  -- #dfe1f9

    -- Tertiary (dusty rose)
    tertiary                 = hex("editorInfo.foreground"),           -- #e5bad8
    tertiary_container       = hex("terminal.ansiBrightGreen"),        -- #5d3c55

    -- Error
    error                    = hex("editorError.foreground"),          -- #ffb4ab
    error_container          = hex("terminal.ansiBrightRed"),          -- #93000a

    -- Selection / highlights (with alpha baked into logic)
    selection_bg             = hex("editor.selectionBackground"),      -- #b9c3ff33 → use primary + blend
    word_highlight           = hex("editor.wordHighlightBackground"),  -- secondary tint
    word_highlight_strong    = hex("editor.wordHighlightStrongBackground"), -- tertiary tint

    -- Git
    git_added                = hex("editorGutter.addedBackground"),    -- #b9c3ff
    git_modified             = hex("editorGutter.modifiedBackground"), -- #c3c5dd
    git_deleted              = hex("editorGutter.deletedBackground"),  -- #ffb4ab
  }
end

-- ---------------------------------------------------------------------------
-- Helper: set highlight
-- ---------------------------------------------------------------------------
local function hl(group, opts)
  local ok, err = pcall(vim.api.nvim_set_hl, 0, group, opts)
  if not ok then
    vim.notify("matugen: hl error on " .. group .. ": " .. err, vim.log.levels.WARN)
  end
end

-- ---------------------------------------------------------------------------
-- Apply all highlights
-- ---------------------------------------------------------------------------
local function apply(c)
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") then vim.cmd("syntax reset") end
  vim.g.colors_name = "matugen"
  vim.o.termguicolors = true

  -- ── LAYER 1: Core editor ────────────────────────────────────────────────

  -- Normal: no bg → transparency falls through to Kitty/Hyprland blur
  hl("Normal",          { fg = c.on_surface,          bg = nil })
  hl("NormalNC",        { fg = c.on_surface_variant,  bg = nil })
  hl("NormalFloat",     { fg = c.on_surface,          bg = c.surface_container })
  hl("Normal",          { fg = c.on_surface,          bg = c.surface }) -- nvim background

  hl("FloatBorder",     { fg = c.primary,             bg = c.surface_container })
  hl("FloatTitle",      { fg = c.primary,             bg = c.surface_container, bold = true })
  hl("FloatFooter",     { fg = c.outline,             bg = c.surface_container })

  hl("Cursor",          { fg = c.on_primary,          bg = c.primary })
  hl("CursorLine",      { bg = c.surface_high })
  hl("CursorLineNr",    { fg = c.primary,             bold = true })
  hl("LineNr",          { fg = c.outline })
  hl("SignColumn",      { fg = c.outline,             bg = nil })
  hl("FoldColumn",      { fg = c.outline_variant,     bg = nil })
  hl("Folded",          { fg = c.outline,             bg = c.surface_high })

  hl("Visual",          { fg = c.on_primary_container, bg = c.primary_container })
  hl("VisualNOS",       { fg = c.on_primary_container, bg = c.primary_container })

  hl("Search",          { fg = c.on_primary,          bg = c.primary })
  hl("IncSearch",       { fg = c.on_primary,          bg = c.primary,           bold = true })
  hl("CurSearch",       { fg = c.on_primary,          bg = c.primary,           bold = true })
  hl("Substitute",      { fg = c.on_primary,          bg = c.primary_container })

  hl("MatchParen",      { fg = c.primary,             underline = true,         bold = true })

  hl("StatusLine",      { fg = c.on_surface_variant,  bg = c.surface_container })
  hl("StatusLineNC",    { fg = c.outline,             bg = c.surface_low })
  hl("WinBar",          { fg = c.outline,             bg = nil })
  hl("WinBarNC",        { fg = c.outline_variant,     bg = nil })
  hl("WinSeparator",    { fg = c.outline_variant,     bg = nil })

  hl("TabLine",         { fg = c.outline,             bg = c.surface_low })
  hl("TabLineSel",      { fg = c.primary,             bg = c.surface_high,      bold = true })
  hl("TabLineFill",     { bg = c.surface_low })

  hl("Pmenu",           { fg = c.on_surface,          bg = c.surface_container })
  hl("PmenuSel",        { fg = c.on_primary_container, bg = c.primary_container })
  hl("PmenuSbar",       { bg = c.surface_high })
  hl("PmenuThumb",      { bg = c.primary_container })
  hl("PmenuBorder",     { fg = c.primary,             bg = c.surface_container })
  hl("PmenuExtra",      { fg = c.outline,             bg = c.surface_container })
  hl("PmenuExtraSel",   { fg = c.on_secondary_container, bg = c.primary_container })

  hl("NonText",         { fg = c.outline_variant })
  hl("SpecialKey",      { fg = c.outline_variant })
  hl("Whitespace",      { fg = c.outline_variant })
  hl("EndOfBuffer",     { fg = c.outline_variant })

  hl("Directory",       { fg = c.primary,             bold = true })
  hl("Title",           { fg = c.primary,             bold = true })
  hl("Question",        { fg = c.primary })
  hl("MoreMsg",         { fg = c.primary })
  hl("ModeMsg",         { fg = c.on_surface,          bold = true })
  hl("MsgArea",         { fg = c.on_surface_variant })
  hl("ErrorMsg",        { fg = c.error })
  hl("WarningMsg",      { fg = c.tertiary })

  hl("SpellBad",        { undercurl = true,           sp = c.error })
  hl("SpellCap",        { undercurl = true,           sp = c.primary })
  hl("SpellRare",       { undercurl = true,           sp = c.tertiary })
  hl("SpellLocal",      { undercurl = true,           sp = c.secondary })

  hl("QuickFixLine",    { fg = c.on_primary_container, bg = c.primary_container })
  hl("qfLineNr",        { fg = c.primary })
  hl("qfFileName",      { fg = c.tertiary })

  hl("DiffAdd",         { fg = c.git_added,           bg = c.surface_high })
  hl("DiffChange",      { fg = c.git_modified,        bg = c.surface_high })
  hl("DiffDelete",      { fg = c.git_deleted,         bg = c.surface_high })
  hl("DiffText",        { fg = c.on_surface,          bg = c.primary_container })

  hl("Conceal",         { fg = c.outline })
  hl("ColorColumn",     { bg = c.surface_high })

  -- ── LAYER 2: Syntax (legacy + Treesitter @-groups) ───────────────────────

  -- Legacy syntax groups (fallback for non-TS files)
  hl("Comment",         { fg = c.outline,             italic = true })
  hl("Constant",        { fg = c.tertiary })
  hl("String",          { fg = c.tertiary,            italic = true })
  hl("Character",       { fg = c.tertiary })
  hl("Number",          { fg = c.secondary })
  hl("Boolean",         { fg = c.primary,             bold = true })
  hl("Float",           { fg = c.secondary })
  hl("Identifier",      { fg = c.on_surface })
  hl("Function",        { fg = c.secondary })
  hl("Statement",       { fg = c.primary })
  hl("Conditional",     { fg = c.primary })
  hl("Repeat",          { fg = c.primary })
  hl("Label",           { fg = c.primary })
  hl("Operator",        { fg = c.secondary })
  hl("Keyword",         { fg = c.primary,             bold = true })
  hl("Exception",       { fg = c.error })
  hl("PreProc",         { fg = c.secondary })
  hl("Include",         { fg = c.secondary })
  hl("Define",          { fg = c.secondary })
  hl("Macro",           { fg = c.secondary })
  hl("PreCondit",       { fg = c.secondary })
  hl("Type",            { fg = c.primary })
  hl("StorageClass",    { fg = c.primary })
  hl("Structure",       { fg = c.primary })
  hl("Typedef",         { fg = c.primary })
  hl("Special",         { fg = c.tertiary })
  hl("SpecialChar",     { fg = c.tertiary })
  hl("Tag",             { fg = c.primary })
  hl("Delimiter",       { fg = c.outline })
  hl("SpecialComment",  { fg = c.outline,             italic = true })
  hl("Debug",           { fg = c.error })
  hl("Underlined",      { underline = true })
  hl("Ignore",          { fg = c.outline_variant })
  hl("Error",           { fg = c.error })
  hl("Todo",            { fg = c.on_primary,          bg = c.primary,           bold = true })

  -- Treesitter @ groups
  hl("@comment",                    { fg = c.outline,             italic = true })
  hl("@comment.documentation",      { fg = c.outline,             italic = true })
  hl("@comment.error",              { fg = c.error,               italic = true })
  hl("@comment.warning",            { fg = c.tertiary,            italic = true })
  hl("@comment.todo",               { fg = c.on_primary,          bg = c.primary,           bold = true })
  hl("@comment.note",               { fg = c.on_primary_container, bg = c.primary_container, bold = true })

  hl("@string",                     { fg = c.tertiary,            italic = true })
  hl("@string.regexp",              { fg = c.tertiary })
  hl("@string.escape",              { fg = c.primary,             bold = true })
  hl("@string.special",             { fg = c.tertiary })
  hl("@string.special.url",         { fg = c.primary,             underline = true })
  hl("@string.special.symbol",      { fg = c.tertiary })

  hl("@character",                  { fg = c.tertiary })
  hl("@character.special",          { fg = c.primary })

  hl("@boolean",                    { fg = c.primary,             bold = true })
  hl("@number",                     { fg = c.secondary })
  hl("@number.float",               { fg = c.secondary })

  hl("@variable",                   { fg = c.on_surface })
  hl("@variable.builtin",           { fg = c.primary,             italic = true })
  hl("@variable.parameter",         { fg = c.on_surface_variant })
  hl("@variable.parameter.builtin", { fg = c.primary,             italic = true })
  hl("@variable.member",            { fg = c.tertiary })

  hl("@constant",                   { fg = c.tertiary,            bold = true })
  hl("@constant.builtin",           { fg = c.primary,             bold = true })
  hl("@constant.macro",             { fg = c.secondary,           bold = true })

  hl("@module",                     { fg = c.on_surface_variant })
  hl("@module.builtin",             { fg = c.primary,             italic = true })
  hl("@label",                      { fg = c.primary })

  hl("@function",                   { fg = c.secondary })
  hl("@function.builtin",           { fg = c.secondary,           italic = true })
  hl("@function.call",              { fg = c.secondary })
  hl("@function.macro",             { fg = c.secondary,           bold = true })
  hl("@function.method",            { fg = c.tertiary })
  hl("@function.method.call",       { fg = c.tertiary })

  hl("@constructor",                { fg = c.primary })
  hl("@operator",                   { fg = c.secondary })

  hl("@keyword",                    { fg = c.primary,             bold = true })
  hl("@keyword.coroutine",          { fg = c.primary,             bold = true })
  hl("@keyword.function",           { fg = c.primary,             bold = true })
  hl("@keyword.operator",           { fg = c.secondary })
  hl("@keyword.import",             { fg = c.secondary })
  hl("@keyword.type",               { fg = c.primary })
  hl("@keyword.modifier",           { fg = c.primary })
  hl("@keyword.repeat",             { fg = c.primary,             bold = true })
  hl("@keyword.return",             { fg = c.primary,             bold = true })
  hl("@keyword.debug",              { fg = c.error })
  hl("@keyword.exception",          { fg = c.error })
  hl("@keyword.conditional",        { fg = c.primary,             bold = true })
  hl("@keyword.conditional.ternary",{ fg = c.secondary })
  hl("@keyword.directive",          { fg = c.secondary })
  hl("@keyword.directive.define",   { fg = c.secondary })

  hl("@type",                       { fg = c.primary })
  hl("@type.builtin",               { fg = c.primary,             italic = true })
  hl("@type.definition",            { fg = c.primary })

  hl("@attribute",                  { fg = c.secondary })
  hl("@attribute.builtin",          { fg = c.secondary,           italic = true })
  hl("@property",                   { fg = c.tertiary })

  hl("@punctuation.delimiter",      { fg = c.outline })
  hl("@punctuation.bracket",        { fg = c.on_surface_variant })
  hl("@punctuation.special",        { fg = c.secondary })

  hl("@tag",                        { fg = c.primary })
  hl("@tag.builtin",                { fg = c.primary,             italic = true })
  hl("@tag.attribute",              { fg = c.tertiary })
  hl("@tag.delimiter",              { fg = c.outline })

  hl("@diff.plus",                  { fg = c.git_added })
  hl("@diff.minus",                 { fg = c.git_deleted })
  hl("@diff.delta",                 { fg = c.git_modified })

  hl("@markup.strong",              { bold = true })
  hl("@markup.italic",              { italic = true })
  hl("@markup.strikethrough",       { strikethrough = true })
  hl("@markup.underline",           { underline = true })
  hl("@markup.heading",             { fg = c.primary,             bold = true })
  hl("@markup.heading.1",           { fg = c.primary,             bold = true })
  hl("@markup.heading.2",           { fg = c.secondary,           bold = true })
  hl("@markup.heading.3",           { fg = c.tertiary,            bold = true })
  hl("@markup.heading.4",           { fg = c.on_surface_variant,  bold = true })
  hl("@markup.heading.5",           { fg = c.outline,             bold = true })
  hl("@markup.heading.6",           { fg = c.outline_variant,     bold = true })
  hl("@markup.quote",               { fg = c.outline,             italic = true })
  hl("@markup.math",                { fg = c.tertiary })
  hl("@markup.link",                { fg = c.primary,             underline = true })
  hl("@markup.link.label",          { fg = c.secondary })
  hl("@markup.link.url",            { fg = c.primary,             underline = true, italic = true })
  hl("@markup.raw",                 { fg = c.on_surface_variant })
  hl("@markup.raw.block",           { fg = c.on_surface_variant })
  hl("@markup.list",                { fg = c.primary })
  hl("@markup.list.checked",        { fg = c.git_added })
  hl("@markup.list.unchecked",      { fg = c.outline })

  -- ── LAYER 3: LSP semantic tokens ────────────────────────────────────────

  hl("@lsp.type.class",             { fg = c.primary })
  hl("@lsp.type.comment",           { fg = c.outline,             italic = true })
  hl("@lsp.type.decorator",         { fg = c.secondary })
  hl("@lsp.type.enum",              { fg = c.primary })
  hl("@lsp.type.enumMember",        { fg = c.tertiary,            bold = true })
  hl("@lsp.type.event",             { fg = c.primary })
  hl("@lsp.type.function",          { fg = c.secondary })
  hl("@lsp.type.interface",         { fg = c.primary_container })
  hl("@lsp.type.keyword",           { fg = c.primary,             bold = true })
  hl("@lsp.type.macro",             { fg = c.secondary,           bold = true })
  hl("@lsp.type.method",            { fg = c.tertiary })
  hl("@lsp.type.modifier",          { fg = c.primary })
  hl("@lsp.type.namespace",         { fg = c.on_surface_variant })
  hl("@lsp.type.number",            { fg = c.secondary })
  hl("@lsp.type.operator",          { fg = c.secondary })
  hl("@lsp.type.parameter",         { fg = c.on_surface_variant })
  hl("@lsp.type.property",          { fg = c.tertiary })
  hl("@lsp.type.regexp",            { fg = c.tertiary })
  hl("@lsp.type.string",            { fg = c.tertiary,            italic = true })
  hl("@lsp.type.struct",            { fg = c.primary })
  hl("@lsp.type.type",              { fg = c.primary })
  hl("@lsp.type.typeParameter",     { fg = c.secondary })
  hl("@lsp.type.variable",          { fg = c.on_surface })

  hl("@lsp.mod.deprecated",         { strikethrough = true })
  hl("@lsp.mod.readonly",           { italic = true })
  hl("@lsp.mod.static",             { bold = true })
  hl("@lsp.mod.defaultLibrary",     { italic = true })
  hl("@lsp.mod.documentation",      { italic = true })

  -- ── LAYER 4: LSP diagnostic UI ──────────────────────────────────────────

  hl("DiagnosticError",             { fg = c.error })
  hl("DiagnosticWarn",              { fg = c.tertiary })
  hl("DiagnosticInfo",              { fg = c.secondary })
  hl("DiagnosticHint",              { fg = c.primary })
  hl("DiagnosticOk",                { fg = c.git_added })

  hl("DiagnosticUnderlineError",    { undercurl = true,           sp = c.error })
  hl("DiagnosticUnderlineWarn",     { undercurl = true,           sp = c.tertiary })
  hl("DiagnosticUnderlineInfo",     { undercurl = true,           sp = c.secondary })
  hl("DiagnosticUnderlineHint",     { undercurl = true,           sp = c.primary })

  hl("DiagnosticVirtualTextError",  { fg = c.error,               bg = c.surface_high,  italic = true })
  hl("DiagnosticVirtualTextWarn",   { fg = c.tertiary,            bg = c.surface_high,  italic = true })
  hl("DiagnosticVirtualTextInfo",   { fg = c.secondary,           bg = c.surface_high,  italic = true })
  hl("DiagnosticVirtualTextHint",   { fg = c.primary,             bg = c.surface_high,  italic = true })

  hl("DiagnosticSignError",         { fg = c.error })
  hl("DiagnosticSignWarn",          { fg = c.tertiary })
  hl("DiagnosticSignInfo",          { fg = c.secondary })
  hl("DiagnosticSignHint",          { fg = c.primary })

  hl("DiagnosticFloatingError",     { fg = c.error,               bg = c.surface_container })
  hl("DiagnosticFloatingWarn",      { fg = c.tertiary,            bg = c.surface_container })
  hl("DiagnosticFloatingInfo",      { fg = c.secondary,           bg = c.surface_container })
  hl("DiagnosticFloatingHint",      { fg = c.primary,             bg = c.surface_container })

  hl("LspReferenceText",            { bg = c.surface_high })
  hl("LspReferenceRead",            { bg = c.surface_high })
  hl("LspReferenceWrite",           { bg = c.primary_container,   underline = true })
  hl("LspInlayHint",                { fg = c.outline,             bg = c.surface_high,  italic = true })
  hl("LspCodeLens",                 { fg = c.outline,             italic = true })
  hl("LspCodeLensSeparator",        { fg = c.outline_variant })
  hl("LspSignatureActiveParameter", { fg = c.primary,             bold = true,          underline = true })

  -- ── LAYER 5: Plugins ────────────────────────────────────────────────────

  -- gitsigns
  hl("GitSignsAdd",                 { fg = c.git_added })
  hl("GitSignsChange",              { fg = c.git_modified })
  hl("GitSignsDelete",              { fg = c.git_deleted })
  hl("GitSignsAddNr",               { fg = c.git_added })
  hl("GitSignsChangeNr",            { fg = c.git_modified })
  hl("GitSignsDeleteNr",            { fg = c.git_deleted })
  hl("GitSignsAddLn",               { bg = c.surface_high })
  hl("GitSignsChangeLn",            { bg = c.surface_high })
  hl("GitSignsCurrentLineBlame",    { fg = c.outline,             italic = true })

  -- bufferline
  hl("BufferLineBackground",        { fg = c.outline,             bg = c.surface_low })
  hl("BufferLineFill",              { bg = c.surface_low })
  hl("BufferLineBufferSelected",    { fg = c.on_surface,          bg = c.surface_high,  bold = true })
  hl("BufferLineBufferVisible",     { fg = c.on_surface_variant,  bg = c.surface_container })
  hl("BufferLineModified",          { fg = c.tertiary,            bg = c.surface_low })
  hl("BufferLineModifiedSelected",  { fg = c.tertiary,            bg = c.surface_high })
  hl("BufferLineModifiedVisible",   { fg = c.tertiary,            bg = c.surface_container })
  hl("BufferLineIndicatorSelected", { fg = c.primary,             bg = c.surface_high })
  hl("BufferLineSeparator",         { fg = c.outline_variant,     bg = c.surface_low })
  hl("BufferLineSeparatorSelected", { fg = c.outline_variant,     bg = c.surface_high })
  hl("BufferLineTab",               { fg = c.outline,             bg = c.surface_low })
  hl("BufferLineTabSelected",       { fg = c.primary,             bg = c.surface_high,  bold = true })
  hl("BufferLineTabSeparator",      { fg = c.outline_variant,     bg = c.surface_low })
  hl("BufferLineTabSeparatorSelected", { fg = c.primary,          bg = c.surface_high })
  hl("BufferLineCloseButton",       { fg = c.outline,             bg = c.surface_low })
  hl("BufferLineCloseButtonSelected", { fg = c.error,             bg = c.surface_high })
  hl("BufferLineError",             { fg = c.error,               bg = c.surface_low })
  hl("BufferLineErrorSelected",     { fg = c.error,               bg = c.surface_high,  bold = true })
  hl("BufferLineWarning",           { fg = c.tertiary,            bg = c.surface_low })
  hl("BufferLineWarningSelected",   { fg = c.tertiary,            bg = c.surface_high,  bold = true })
  hl("BufferLineInfo",              { fg = c.secondary,           bg = c.surface_low })
  hl("BufferLineInfoSelected",      { fg = c.secondary,           bg = c.surface_high,  bold = true })
  hl("BufferLineHint",              { fg = c.primary,             bg = c.surface_low })
  hl("BufferLineHintSelected",      { fg = c.primary,             bg = c.surface_high,  bold = true })
  hl("BufferLineDiagnostic",        { fg = c.outline,             bg = c.surface_low })
  hl("BufferLineDiagnosticSelected",{ fg = c.outline,             bg = c.surface_high })
  hl("BufferLineNumbers",           { fg = c.outline,             bg = c.surface_low })
  hl("BufferLineNumbersSelected",   { fg = c.primary,             bg = c.surface_high,  bold = true })
  hl("BufferLinePick",              { fg = c.error,               bg = c.surface_low,   bold = true })
  hl("BufferLinePickSelected",      { fg = c.error,               bg = c.surface_high,  bold = true })
  hl("BufferLineGroupSeparator",    { fg = c.outline_variant,     bg = c.surface_low })
  hl("BufferLineGroupLabel",        { fg = c.primary,             bg = c.surface_container })
  hl("BufferLineOffsetSeparator",   { fg = c.outline_variant,     bg = c.surface_low })
  hl("BufferLineTruncMarker",       { fg = c.outline,             bg = c.surface_low })

  -- lualine (base groups — lualine uses these internally)
  hl("lualine_a_normal",            { fg = c.on_primary,          bg = c.primary,           bold = true })
  hl("lualine_a_insert",            { fg = c.on_primary,          bg = c.tertiary,          bold = true })
  hl("lualine_a_visual",            { fg = c.on_primary,          bg = c.secondary,         bold = true })
  hl("lualine_a_replace",           { fg = c.surface,             bg = c.error,             bold = true })
  hl("lualine_a_command",           { fg = c.on_primary,          bg = c.secondary_container, bold = true })
  hl("lualine_b_normal",            { fg = c.on_surface_variant,  bg = c.surface_container })
  hl("lualine_c_normal",            { fg = c.outline,             bg = nil })
  hl("lualine_b_diagnostics_error", { fg = c.error,               bg = c.surface_container })
  hl("lualine_b_diagnostics_warn",  { fg = c.tertiary,            bg = c.surface_container })
  hl("lualine_b_diagnostics_info",  { fg = c.secondary,           bg = c.surface_container })
  hl("lualine_b_diagnostics_hint",  { fg = c.primary,             bg = c.surface_container })

  -- blink.cmp
  hl("BlinkCmpMenu",                { fg = c.on_surface,          bg = c.surface_container })
  hl("BlinkCmpMenuBorder",          { fg = c.primary,             bg = c.surface_container })
  hl("BlinkCmpMenuSelection",       { fg = c.on_primary_container, bg = c.primary_container })
  hl("BlinkCmpScrollBarThumb",      { bg = c.primary_container })
  hl("BlinkCmpScrollBarGutter",     { bg = c.surface_high })
  hl("BlinkCmpLabel",               { fg = c.on_surface })
  hl("BlinkCmpLabelDeprecated",     { fg = c.outline,             strikethrough = true })
  hl("BlinkCmpLabelMatch",          { fg = c.primary,             bold = true })
  hl("BlinkCmpLabelDetail",         { fg = c.outline })
  hl("BlinkCmpLabelDescription",    { fg = c.outline })
  hl("BlinkCmpKind",                { fg = c.secondary })
  hl("BlinkCmpKindClass",           { fg = c.primary })
  hl("BlinkCmpKindColor",           { fg = c.tertiary })
  hl("BlinkCmpKindConstant",        { fg = c.tertiary })
  hl("BlinkCmpKindConstructor",     { fg = c.primary })
  hl("BlinkCmpKindEnum",            { fg = c.primary })
  hl("BlinkCmpKindEnumMember",      { fg = c.tertiary })
  hl("BlinkCmpKindEvent",           { fg = c.primary })
  hl("BlinkCmpKindField",           { fg = c.secondary })
  hl("BlinkCmpKindFile",            { fg = c.outline })
  hl("BlinkCmpKindFolder",          { fg = c.primary })
  hl("BlinkCmpKindFunction",        { fg = c.secondary })
  hl("BlinkCmpKindInterface",       { fg = c.primary_container })
  hl("BlinkCmpKindKeyword",         { fg = c.tertiary })
  hl("BlinkCmpKindMethod",          { fg = c.tertiary })
  hl("BlinkCmpKindModule",          { fg = c.on_surface_variant })
  hl("BlinkCmpKindOperator",        { fg = c.secondary })
  hl("BlinkCmpKindProperty",        { fg = c.tertiary })
  hl("BlinkCmpKindReference",       { fg = c.primary })
  hl("BlinkCmpKindSnippet",         { fg = c.on_surface_variant })
  hl("BlinkCmpKindStruct",          { fg = c.primary })
  hl("BlinkCmpKindText",            { fg = c.on_surface_variant })
  hl("BlinkCmpKindTypeParameter",   { fg = c.secondary })
  hl("BlinkCmpKindUnit",            { fg = c.tertiary })
  hl("BlinkCmpKindValue",           { fg = c.secondary })
  hl("BlinkCmpKindVariable",        { fg = c.primary })
  hl("BlinkCmpDoc",                 { fg = c.on_surface,          bg = c.surface_container })
  hl("BlinkCmpDocBorder",           { fg = c.outline_variant,     bg = c.surface_container })
  hl("BlinkCmpDocSeparator",        { fg = c.outline_variant,     bg = c.surface_container })
  hl("BlinkCmpDocCursorLine",       { bg = c.surface_high })
  hl("BlinkCmpSignatureHelp",       { fg = c.on_surface,          bg = c.surface_container })
  hl("BlinkCmpSignatureHelpBorder", { fg = c.outline_variant,     bg = c.surface_container })
  hl("BlinkCmpSignatureHelpActiveParameter", { fg = c.primary,    bold = true, underline = true })

  -- noice
  hl("NoiceCmdline",                { fg = c.on_surface,          bg = c.surface_container })
  hl("NoiceCmdlineIcon",            { fg = c.primary })
  hl("NoiceCmdlineIconSearch",      { fg = c.secondary })
  hl("NoiceCmdlinePopup",           { fg = c.on_surface,          bg = c.surface_container })
  hl("NoiceCmdlinePopupBorder",     { fg = c.primary,             bg = c.surface_container })
  hl("NoiceCmdlinePopupBorderSearch",{ fg = c.secondary,          bg = c.surface_container })
  hl("NoiceCmdlinePrompt",          { fg = c.primary,             bold = true })
  hl("NoiceConfirm",                { fg = c.on_surface,          bg = c.surface_container })
  hl("NoiceConfirmBorder",          { fg = c.primary,             bg = c.surface_container })
  hl("NoiceFormatConfirm",          { fg = c.on_primary_container, bg = c.primary_container })
  hl("NoiceFormatConfirmDefault",   { fg = c.on_primary,          bg = c.primary,           bold = true })
  hl("NoiceFormatDate",             { fg = c.outline })
  hl("NoiceFormatEvent",            { fg = c.outline })
  hl("NoiceFormatKind",             { fg = c.secondary })
  hl("NoiceFormatLevelDebug",       { fg = c.outline })
  hl("NoiceFormatLevelError",       { fg = c.error })
  hl("NoiceFormatLevelInfo",        { fg = c.secondary })
  hl("NoiceFormatLevelOff",         { fg = c.outline_variant })
  hl("NoiceFormatLevelTrace",       { fg = c.outline_variant })
  hl("NoiceFormatLevelWarn",        { fg = c.tertiary })
  hl("NoiceFormatProgressDone",     { fg = c.on_primary,          bg = c.primary })
  hl("NoiceFormatProgressTodo",     { fg = c.primary,             bg = c.surface_container })
  hl("NoiceFormatTitle",            { fg = c.primary,             bold = true })
  hl("NoiceLspProgressClient",      { fg = c.primary,             bold = true })
  hl("NoiceLspProgressSpinner",     { fg = c.secondary })
  hl("NoiceLspProgressTitle",       { fg = c.on_surface_variant })
  hl("NoiceMini",                   { fg = c.on_surface_variant,  bg = c.surface_container })
  hl("NoicePopup",                  { fg = c.on_surface,          bg = c.surface_container })
  hl("NoicePopupBorder",            { fg = c.outline_variant,     bg = c.surface_container })
  hl("NoicePopupmenu",              { fg = c.on_surface,          bg = c.surface_container })
  hl("NoicePopupmenuBorder",        { fg = c.primary,             bg = c.surface_container })
  hl("NoicePopupmenuMatch",         { fg = c.primary,             bold = true })
  hl("NoicePopupmenuSelected",      { fg = c.on_primary_container, bg = c.primary_container })
  hl("NoiceScrollbar",              { bg = c.surface_high })
  hl("NoiceScrollbarThumb",         { bg = c.primary_container })
  hl("NoiceSplit",                  { fg = c.on_surface,          bg = nil })
  hl("NoiceSplitBorder",            { fg = c.outline_variant,     bg = nil })
  hl("NoiceVirtualText",            { fg = c.outline,             italic = true })

  -- telescope
  hl("TelescopeBorder",             { fg = c.primary,             bg = c.surface_container })
  hl("TelescopeNormal",             { fg = c.on_surface,          bg = c.surface_container })
  hl("TelescopeTitle",              { fg = c.on_primary,          bg = c.primary,           bold = true })
  hl("TelescopePromptNormal",       { fg = c.on_surface,          bg = c.surface_high })
  hl("TelescopePromptBorder",       { fg = c.primary,             bg = c.surface_high })
  hl("TelescopePromptTitle",        { fg = c.on_primary,          bg = c.primary,           bold = true })
  hl("TelescopePromptPrefix",       { fg = c.primary,             bg = c.surface_high })
  hl("TelescopePromptCounter",      { fg = c.outline,             bg = c.surface_high })
  hl("TelescopePreviewNormal",      { fg = c.on_surface,          bg = c.surface_container })
  hl("TelescopePreviewBorder",      { fg = c.outline_variant,     bg = c.surface_container })
  hl("TelescopePreviewTitle",       { fg = c.on_primary_container, bg = c.primary_container, bold = true })
  hl("TelescopeResultsNormal",      { fg = c.on_surface,          bg = c.surface_container })
  hl("TelescopeResultsBorder",      { fg = c.outline_variant,     bg = c.surface_container })
  hl("TelescopeResultsTitle",       { fg = c.outline,             bg = c.surface_container })
  hl("TelescopeSelection",          { fg = c.on_primary_container, bg = c.primary_container })
  hl("TelescopeSelectionCaret",     { fg = c.primary,             bg = c.primary_container })
  hl("TelescopeMultiSelection",     { fg = c.tertiary,            bg = c.surface_high })
  hl("TelescopeMultiIcon",          { fg = c.tertiary })
  hl("TelescopeMatching",           { fg = c.primary,             bold = true })
  hl("TelescopeResultsDiffAdd",     { fg = c.git_added })
  hl("TelescopeResultsDiffChange",  { fg = c.git_modified })
  hl("TelescopeResultsDiffDelete",  { fg = c.git_deleted })
  hl("TelescopeResultsDiffUntracked",{ fg = c.tertiary })

  -- snacks.nvim
  hl("SnacksNormal",                { fg = c.on_surface,          bg = c.surface_container })
  hl("SnacksNormalNC",              { fg = c.on_surface_variant,  bg = c.surface_container })
  hl("SnacksBorder",                { fg = c.outline_variant,     bg = c.surface_container })
  hl("SnacksBackdrop",              { bg = c.surface,             blend = 40 })
  hl("SnacksDashboardNormal",       { fg = c.on_surface,          bg = nil })
  hl("SnacksDashboardDesc",         { fg = c.on_surface_variant })
  hl("SnacksDashboardFile",         { fg = c.primary })
  hl("SnacksDashboardDir",          { fg = c.outline })
  hl("SnacksDashboardFooter",       { fg = c.outline,             italic = true })
  hl("SnacksDashboardHeader",       { fg = c.primary,             bold = true })
  hl("SnacksDashboardIcon",         { fg = c.primary })
  hl("SnacksDashboardKey",          { fg = c.secondary,           bold = true })
  hl("SnacksDashboardSpecial",      { fg = c.tertiary })
  hl("SnacksDashboardTitle",        { fg = c.primary,             bold = true })
  hl("SnacksNotifierBorderError",   { fg = c.error })
  hl("SnacksNotifierBorderWarn",    { fg = c.tertiary })
  hl("SnacksNotifierBorderInfo",    { fg = c.secondary })
  hl("SnacksNotifierBorderDebug",   { fg = c.outline })
  hl("SnacksNotifierBorderTrace",   { fg = c.outline_variant })
  hl("SnacksNotifierIconError",     { fg = c.error })
  hl("SnacksNotifierIconWarn",      { fg = c.tertiary })
  hl("SnacksNotifierIconInfo",      { fg = c.secondary })
  hl("SnacksNotifierIconDebug",     { fg = c.outline })
  hl("SnacksNotifierIconTrace",     { fg = c.outline_variant })
  hl("SnacksNotifierTitleError",    { fg = c.error,               bold = true })
  hl("SnacksNotifierTitleWarn",     { fg = c.tertiary,            bold = true })
  hl("SnacksNotifierTitleInfo",     { fg = c.secondary,           bold = true })
  hl("SnacksNotifierTitleDebug",    { fg = c.outline,             bold = true })
  hl("SnacksNotifierTitleTrace",    { fg = c.outline_variant,     bold = true })
  hl("SnacksPickerBorder",          { fg = c.primary,             bg = c.surface_container })
  hl("SnacksPickerTitle",           { fg = c.on_primary,          bg = c.primary,           bold = true })
  hl("SnacksPickerMatch",           { fg = c.primary,             bold = true })
  hl("SnacksPickerSelected",        { fg = c.tertiary })
  hl("SnacksPickerDir",             { fg = c.outline })
  hl("SnacksPickerFile",            { fg = c.on_surface })
  hl("SnacksPickerPathHidden",      { fg = c.outline_variant })
  hl("SnacksPickerToggle",          { fg = c.secondary,           bold = true })
  hl("SnacksPickerListCursorLine",  { bg = c.primary_container })
  hl("SnacksPickerPreviewCursorLine",{ bg = c.surface_high })
  hl("SnacksIndent",                { fg = c.outline_variant })
  hl("SnacksIndentScope",           { fg = c.primary })
  hl("SnacksZenBar",                { fg = c.outline_variant,     bg = nil })
  hl("SnacksScrollbar",             { fg = c.primary_container })
  hl("SnacksInputNormal",           { fg = c.on_surface,          bg = c.surface_high })
  hl("SnacksInputBorder",           { fg = c.primary,             bg = c.surface_high })
  hl("SnacksInputTitle",            { fg = c.on_primary,          bg = c.primary })
  hl("SnacksProfilerBadgeHl",       { fg = c.on_primary,          bg = c.primary })

  -- trouble.nvim
  hl("TroubleNormal",               { fg = c.on_surface,          bg = nil })
  hl("TroubleNormalNC",             { fg = c.on_surface_variant,  bg = nil })
  hl("TroubleCount",                { fg = c.on_primary_container, bg = c.primary_container })
  hl("TroublePos",                  { fg = c.outline })
  hl("TroubleLocation",             { fg = c.outline })
  hl("TroubleFile",                 { fg = c.primary,             bold = true })
  hl("TroubleSource",               { fg = c.outline })
  hl("TroubleCode",                 { fg = c.outline })
  hl("TroubleText",                 { fg = c.on_surface })
  hl("TroubleIconError",            { fg = c.error })
  hl("TroubleIconWarning",          { fg = c.tertiary })
  hl("TroubleIconInformation",      { fg = c.secondary })
  hl("TroubleIconHint",             { fg = c.primary })
  hl("TroubleIndent",               { fg = c.outline_variant })
  hl("TroubleIndentFoldOpen",       { fg = c.primary })
  hl("TroubleIndentFoldClosed",     { fg = c.outline })
  hl("TroubleFoldIcon",             { fg = c.primary })
  hl("TroubleIconDirectory",        { fg = c.primary })
  hl("TroubleIconFile",             { fg = c.outline })

  -- which-key
  hl("WhichKey",                    { fg = c.primary,             bold = true })
  hl("WhichKeyBorder",              { fg = c.outline_variant,     bg = c.surface_container })
  hl("WhichKeyGroup",               { fg = c.secondary })
  hl("WhichKeyDesc",                { fg = c.on_surface })
  hl("WhichKeySeparator",           { fg = c.outline_variant })
  hl("WhichKeyValue",               { fg = c.outline })
  hl("WhichKeyNormal",              { fg = c.on_surface,          bg = c.surface_container })
  hl("WhichKeyTitle",               { fg = c.on_primary,          bg = c.primary,           bold = true })
  hl("WhichKeyIcon",                { fg = c.primary })
  hl("WhichKeyIconBlue",            { fg = c.primary })
  hl("WhichKeyIconGreen",           { fg = c.git_added })
  hl("WhichKeyIconRed",             { fg = c.error })
  hl("WhichKeyIconYellow",          { fg = c.tertiary })
  hl("WhichKeyIconPurple",          { fg = c.secondary })
  hl("WhichKeyIconCyan",            { fg = c.on_secondary_container })
  hl("WhichKeyIconGrey",            { fg = c.outline })

  -- dressing.nvim
  hl("DressingNormal",              { fg = c.on_surface,          bg = c.surface_container })
  hl("DressingBorder",              { fg = c.primary,             bg = c.surface_container })
  hl("DressingTitle",               { fg = c.on_primary,          bg = c.primary,           bold = true })
  hl("DressingInputNormal",         { fg = c.on_surface,          bg = c.surface_high })
  hl("DressingInputBorder",         { fg = c.outline,             bg = c.surface_high })

  -- flash.nvim
  hl("FlashBackdrop",               { fg = c.outline })
  hl("FlashCurrent",                { fg = c.on_primary,          bg = c.primary,           bold = true })
  hl("FlashLabel",                  { fg = c.on_primary,          bg = c.primary_container, bold = true })
  hl("FlashMatch",                  { fg = c.primary,             bg = c.surface_high })
  hl("FlashPrompt",                 { fg = c.on_surface,          bg = c.surface_container })
  hl("FlashPromptIcon",             { fg = c.primary,             bg = c.surface_container })
  hl("FlashCursor",                 { fg = c.on_primary,          bg = c.primary })

  -- todo-comments
  hl("TodoBgTODO",                  { fg = c.on_primary,          bg = c.primary,           bold = true })
  hl("TodoFgTODO",                  { fg = c.primary })
  hl("TodoSignTODO",                { fg = c.primary })
  hl("TodoBgFIX",                   { fg = c.surface,             bg = c.error,             bold = true })
  hl("TodoFgFIX",                   { fg = c.error })
  hl("TodoSignFIX",                 { fg = c.error })
  hl("TodoBgWARN",                  { fg = c.surface,             bg = c.tertiary,          bold = true })
  hl("TodoFgWARN",                  { fg = c.tertiary })
  hl("TodoSignWARN",                { fg = c.tertiary })
  hl("TodoBgNOTE",                  { fg = c.on_primary_container, bg = c.primary_container, bold = true })
  hl("TodoFgNOTE",                  { fg = c.secondary })
  hl("TodoSignNOTE",                { fg = c.secondary })
  hl("TodoBgHACK",                  { fg = c.surface,             bg = c.secondary_container, bold = true })
  hl("TodoFgHACK",                  { fg = c.on_secondary_container })
  hl("TodoSignHACK",                { fg = c.on_secondary_container })
  hl("TodoBgPERF",                  { fg = c.surface,             bg = c.tertiary_container, bold = true })
  hl("TodoFgPERF",                  { fg = c.tertiary })
  hl("TodoSignPERF",                { fg = c.tertiary })
  hl("TodoBgTEST",                  { fg = c.surface,             bg = c.secondary,         bold = true })
  hl("TodoFgTEST",                  { fg = c.secondary })
  hl("TodoSignTEST",                { fg = c.secondary })

  -- render-markdown
  hl("RenderMarkdownH1",            { fg = c.primary,             bold = true })
  hl("RenderMarkdownH2",            { fg = c.secondary,           bold = true })
  hl("RenderMarkdownH3",            { fg = c.tertiary,            bold = true })
  hl("RenderMarkdownH4",            { fg = c.on_surface_variant,  bold = true })
  hl("RenderMarkdownH5",            { fg = c.outline,             bold = true })
  hl("RenderMarkdownH6",            { fg = c.outline_variant,     bold = true })
  hl("RenderMarkdownH1Bg",          { bg = c.primary_container })
  hl("RenderMarkdownH2Bg",          { bg = c.surface_high })
  hl("RenderMarkdownH3Bg",          { bg = c.surface_high })
  hl("RenderMarkdownH4Bg",          { bg = c.surface_high })
  hl("RenderMarkdownH5Bg",          { bg = c.surface_high })
  hl("RenderMarkdownH6Bg",          { bg = c.surface_high })
  hl("RenderMarkdownCode",          { bg = c.surface_high })
  hl("RenderMarkdownCodeInline",    { fg = c.tertiary,            bg = c.surface_high })
  hl("RenderMarkdownBullet",        { fg = c.primary })
  hl("RenderMarkdownQuote",         { fg = c.outline,             italic = true })
  hl("RenderMarkdownDash",          { fg = c.outline_variant })
  hl("RenderMarkdownLink",          { fg = c.primary,             underline = true })
  hl("RenderMarkdownWikiLink",      { fg = c.primary,             underline = true })
  hl("RenderMarkdownHighlight",     { bg = c.primary_container })
  hl("RenderMarkdownChecked",       { fg = c.git_added })
  hl("RenderMarkdownUnchecked",     { fg = c.outline })
  hl("RenderMarkdownTableHead",     { fg = c.primary,             bold = true })
  hl("RenderMarkdownTableRow",      { fg = c.on_surface })
  hl("RenderMarkdownTableFill",     { fg = c.outline_variant })
  hl("RenderMarkdownSuccess",       { fg = c.git_added })
  hl("RenderMarkdownInfo",          { fg = c.secondary })
  hl("RenderMarkdownHint",          { fg = c.primary })
  hl("RenderMarkdownWarn",          { fg = c.tertiary })
  hl("RenderMarkdownError",         { fg = c.error })

  -- avante.nvim
  hl("AvanteTitle",                 { fg = c.on_primary,          bg = c.primary,           bold = true })
  hl("AvanteReversedTitle",         { fg = c.primary,             bg = c.surface_container })
  hl("AvanteSubtitle",              { fg = c.on_primary_container, bg = c.primary_container })
  hl("AvanteReversedSubtitle",      { fg = c.primary_container,   bg = c.surface_container })
  hl("AvanteThirdTitle",            { fg = c.on_surface_variant,  bg = c.surface_high })
  hl("AvanteReversedThirdTitle",    { fg = c.surface_high,        bg = c.surface_container })
  hl("AvanteConflictCurrent",       { bg = c.primary_container })
  hl("AvanteConflictIncoming",      { bg = c.tertiary_container })
  hl("AvanteConflictCurrentLabel",  { fg = c.on_primary_container, bg = c.primary_container, bold = true })
  hl("AvanteConflictIncomingLabel", { fg = c.tertiary,            bg = c.tertiary_container, bold = true })
  hl("AvantePopupHint",             { fg = c.outline,             italic = true })
  hl("AvanteInlineHint",            { fg = c.outline,             italic = true })

  -- fzf-lua
  hl("FzfLuaNormal",                { fg = c.on_surface,          bg = c.surface_container })
  hl("FzfLuaBorder",                { fg = c.primary,             bg = c.surface_container })
  hl("FzfLuaTitle",                 { fg = c.on_primary,          bg = c.primary,           bold = true })
  hl("FzfLuaPreviewNormal",         { fg = c.on_surface,          bg = c.surface_container })
  hl("FzfLuaPreviewBorder",         { fg = c.outline_variant,     bg = c.surface_container })
  hl("FzfLuaPreviewTitle",          { fg = c.on_primary_container, bg = c.primary_container, bold = true })
  hl("FzfLuaCursorLine",            { bg = c.primary_container })
  hl("FzfLuaCursorLineNr",          { fg = c.primary,             bg = c.primary_container })
  hl("FzfLuaSearch",                { fg = c.primary,             bold = true })
  hl("FzfLuaBufName",               { fg = c.primary })
  hl("FzfLuaBufNr",                 { fg = c.outline })
  hl("FzfLuaBufFlagCur",            { fg = c.primary })
  hl("FzfLuaBufFlagAlt",            { fg = c.secondary })
  hl("FzfLuaTabTitle",              { fg = c.primary,             bold = true })
  hl("FzfLuaTabMarker",             { fg = c.primary })
  hl("FzfLuaPathColNr",             { fg = c.outline })
  hl("FzfLuaPathLineNr",            { fg = c.outline })
  hl("FzfLuaLiveSym",               { fg = c.primary,             bold = true })
  hl("FzfLuaHeaderBind",            { fg = c.secondary,           bold = true })
  hl("FzfLuaHeaderText",            { fg = c.on_surface_variant })

  -- ── LAYER 6: winblend for floats ────────────────────────────────────────
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "lazy", "mason", "lspinfo", "null-ls-info", "checkhealth" },
    callback = function()
      vim.wo.winblend = 10
    end,
  })
end

-- ---------------------------------------------------------------------------
-- SIGUSR1 handler → hot reload
-- ---------------------------------------------------------------------------
local function setup_signal_handler()
  local ok = pcall(vim.loop.new_signal)
  if not ok then return end

  local signal = vim.loop.new_signal()
  signal:start("sigusr1", vim.schedule_wrap(function()
    vim.notify("matugen: reloaded colorscheme", vim.log.levels.INFO)
    local c = load_colors()
    if c then apply(c) end
  end))
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------
function M.load()
  local c = load_colors()
  if not c then return end
  apply(c)
  setup_signal_handler()
end

return M
