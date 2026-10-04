if vim.g.loaded_treesitter_metal then
  return
end
vim.g.loaded_treesitter_metal = true

vim.filetype.add({
  extension = {
    metal = "metal",
    metalcpp = "metal_cpp",
    metalpp = "metal_cpp",
    ["metal-cpp"] = "metal_cpp",
  },
  pattern = {
    [".*%.metal%.hpp"] = "metal_cpp",
    [".*%.metal%.h"] = "metal_cpp",
  },
})

-- MSL uses its own lexical highlighter; host-side metal-cpp is ordinary C++.
-- Do not let parser managers attach the incompatible C++ parser to shaders.
vim.treesitter.language.register("metal", "metal")
vim.treesitter.language.register("cpp", "metal_cpp")

local group = vim.api.nvim_create_augroup("treesitter-metal", { clear = true })
local function start(buf)
  local ft = vim.bo[buf].filetype
  if ft == "metal" then
    vim.treesitter.stop(buf)
    vim.bo[buf].syntax = "metal"
    return
  end
  if ft ~= "metal_cpp" then
    return
  end
  local ok, err = pcall(vim.treesitter.start, buf, "cpp")
  if not ok then
    vim.notify_once(
      "treesitter-metal: could not start C++ highlighting. Install the cpp parser and queries"
        .. " (:TSInstall cpp), then reopen the buffer.\n" .. tostring(err),
      vim.log.levels.WARN
    )
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "metal", "metal_cpp" },
  callback = function(event)
    start(event.buf)
  end,
})

-- Also attach if the runtime was added after a buffer's FileType event.
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(buf) then
    start(buf)
  end
end
