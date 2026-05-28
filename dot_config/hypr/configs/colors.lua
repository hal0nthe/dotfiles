local M = {}

local color_file = os.getenv("HOME") .. "/.config/hypr/colors.conf"

for line in io.lines(color_file) do
    local name, value = line:match("%$(%w+)%s*=%s*(.+)")

    if name and value then
        M[name] = value
    end
end

return M
