-- Copyright (c) 2023, Robert Mollentze, DevCetra.com

local M = {}

local defaults = {
    colors = {
        n = "#44a8e5", -- Normal
        i = "#c177e5", -- Insert
        v = "#88deff", -- Visual (v, V and Ctrl-V)
        R = "#e5a844", -- Replace
        c = nil,       -- Command (nil keeps the theme colour)
        t = nil,       -- Terminal
    },
}

local config = vim.deepcopy(defaults)
local theme_line_nr = nil

-- Normalises sub-modes like "niI", "V" and "\22" (Ctrl-V) to one key.
local function mode_key(mode)
    local first = mode:sub(1, 1)
    if first == "V" or first == "\22" or first == "s" or first == "S" or first == "\19" then
        return "v"
    end
    return first
end

local function apply()
    local color = config.colors[mode_key(vim.api.nvim_get_mode().mode)]
    if color then
        vim.api.nvim_set_hl(0, "CursorLineNr", { fg = color, bold = true })
        vim.api.nvim_set_hl(0, "LineNr", { fg = color })
    elseif theme_line_nr then
        vim.api.nvim_set_hl(0, "LineNr", theme_line_nr)
    end
end

-- Setup function.
function M.setup(opts)
    config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
    local group = vim.api.nvim_create_augroup("ColorLineNumbersByMode", { clear = true })
    vim.api.nvim_create_autocmd("ModeChanged", { group = group, callback = apply })
    -- Themes reset highlights, so remember the theme colour and re-apply ours.
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function()
            theme_line_nr = vim.api.nvim_get_hl(0, { name = "LineNr", link = false })
            apply()
        end,
    })
    -- Deferred so themes that load after plugins (e.g. NvChad's base46) don't
    -- overwrite the first colour.
    vim.schedule(function()
        theme_line_nr = vim.api.nvim_get_hl(0, { name = "LineNr", link = false })
        apply()
    end)
end

return M
