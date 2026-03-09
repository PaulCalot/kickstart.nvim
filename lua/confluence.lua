-- ── Confluence push ────────────────────────────────────────────────────────
-- Add this to your init.lua (or a separate confluence.lua sourced from it).
--
-- Prerequisites:
--   export CONFLUENCE_URL="https://yourcompany.atlassian.net"
--   export CONFLUENCE_USER="you@example.com"
--   export CONFLUENCE_TOKEN="your_api_token"
--   export CONFLUENCE_SPACE="ENG"
--
-- Keybinds (normal mode, .md files only):
--   <leader>cp   →  push current file to Confluence
--   <leader>cd   →  dry-run (print storage XML to a split, no network call)

local function confluence_cmd(dry_run)
  local script = vim.fn.expand("~/.local/bin/confluence_push.py")  -- adjust path
  local file   = vim.fn.expand("%:p")
  local cmd    = string.format("python3 %s %s", script, file)
  if dry_run then cmd = cmd .. " --dry-run" end
  return cmd
end

-- Push to Confluence
vim.keymap.set("n", "<leader>cp", function()
  local output = vim.fn.systemlist(confluence_cmd(false))
  local ok     = vim.v.shell_error == 0
  local icon   = ok and "✓" or "✗"
  vim.notify(table.concat(output, "\n"), ok and vim.log.levels.INFO or vim.log.levels.ERROR)
end, { desc = "Confluence: push page" })

-- Dry-run: open output in a scratch split
vim.keymap.set("n", "<leader>cd", function()
  local output = vim.fn.systemlist(confluence_cmd(true))
  vim.cmd("botright 20new")
  vim.bo.buftype  = "nofile"
  vim.bo.filetype = "xml"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
end, { desc = "Confluence: dry-run (show storage XML)" })

-- Optional: auto-push on save for files that have a confluence front-matter block
-- (only triggers if the file has a `title:` in front-matter)
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.md",
  callback = function()
    local first_lines = vim.api.nvim_buf_get_lines(0, 0, 5, false)
    local has_fm = vim.tbl_contains(first_lines, "---")
    if not has_fm then return end          -- skip plain .md files without front-matter
    local result = vim.fn.system(confluence_cmd(false))
    if vim.v.shell_error == 0 then
      vim.notify("Confluence: pushed ✓", vim.log.levels.INFO)
    end
  end,
})
