-- Run from the repository root: nvim --clean -i NONE --headless -l tests/run.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.cmd("filetype plugin indent on")
vim.cmd("syntax enable")

local failures, passed = {}, 0
local function test(name, fn)
  local ok, err = xpcall(fn, debug.traceback)
  if ok then
    passed = passed + 1
    print("PASS " .. name)
  else
    failures[#failures + 1] = name .. "\n" .. err
  end
end
local function equal(expected, actual)
  assert(vim.deep_equal(expected, actual), vim.inspect({ expected = expected, actual = actual }))
end
local function buffer(ft)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = ft
  return buf
end

local original_start, original_notify = vim.treesitter.start, vim.notify_once
local started, warnings = {}, {}
vim.treesitter.start = function(buf, lang)
  started[#started + 1] = { buf, lang }
end
vim.notify_once = function(message, level)
  warnings[#warnings + 1] = { message, level }
end
local existing = buffer("metal")
vim.cmd("runtime plugin/treesitter-metal.lua")

test("highlights an already open Metal buffer without a parser", function()
  equal({}, started)
  equal("metal", vim.bo[existing].syntax)
  equal("metal", vim.b[existing].current_syntax)
end)
test("detects supported filenames and preserves ordinary filetypes", function()
  for filename, ft in pairs({
    ["shader.metal"] = "metal",
    ["bridge.metalcpp"] = "metal_cpp",
    ["bridge.metalpp"] = "metal_cpp",
    ["bridge.metal-cpp"] = "metal_cpp",
    ["dir with spaces/bridge.metal.hpp"] = "metal_cpp",
    ["bridge.metal.h"] = "metal_cpp",
    ["normal.cpp"] = "cpp",
    ["normal.hpp"] = "cpp",
    ["normal.c"] = "c",
    ["bridge.metal.hpp.cpp"] = "cpp",
  }) do
    equal(ft, vim.filetype.match({ filename = filename }))
  end
end)
test("new and existing files trigger detection and highlighting", function()
  vim.cmd("edit tests/fixtures/kernel.metal")
  equal("metal", vim.bo.filetype)
  equal("metal", vim.bo.syntax)
  equal({}, started)
  vim.cmd("edit tests/fixtures/not-created.metalcpp")
  equal("metal_cpp", vim.bo.filetype)
  equal({ vim.api.nvim_get_current_buf(), "cpp" }, started[#started])
end)
test("only host-side C++ filetypes use the C++ parser", function()
  equal("metal", vim.treesitter.language.get_lang("metal"))
  for _, ft in ipairs({ "metal_cpp", "cpp" }) do
    equal("cpp", vim.treesitter.language.get_lang(ft))
  end
end)
test("inherits C++ editing settings and undoes them on filetype change", function()
  for _, ft in ipairs({ "metal", "metal_cpp" }) do
    buffer(ft)
    equal("// %s", vim.bo.commentstring)
    equal(true, vim.bo.cindent)
    vim.bo.filetype = "text"
    equal(vim.go.commentstring, vim.bo.commentstring)
    equal(vim.go.cindent, vim.bo.cindent)
  end
end)
test("does not start highlighting for unrelated buffers", function()
  local before = #started
  buffer("cpp")
  buffer("text")
  equal(before, #started)
end)
test("sourcing twice does not duplicate callbacks", function()
  vim.cmd("runtime plugin/treesitter-metal.lua")
  local before = #started
  buffer("metal_cpp")
  equal(before + 1, #started)
end)
test("parser failures are nonfatal and actionable", function()
  vim.treesitter.start = function() error("missing test parser") end
  buffer("metal_cpp")
  assert(warnings[#warnings][1]:find(":TSInstall cpp", 1, true))
  assert(warnings[#warnings][1]:find("missing test parser", 1, true))
  equal(vim.log.levels.WARN, warnings[#warnings][2])
end)
vim.treesitter.start, vim.notify_once = original_start, original_notify

dofile("tests/highlights.lua")(test, equal)

-- Optional real parser + upstream queries; CI always supplies this runtime.
if vim.env.TREESITTER_METAL_TEST_RUNTIME then
  vim.opt.runtimepath:append(vim.env.TREESITTER_METAL_TEST_RUNTIME)
  -- Discard buffers opened while highlighting was stubbed.
  vim.cmd("%bwipeout!")
  test("real C++ highlighting stays confined to host-side code", function()
    assert(vim.treesitter.query.get("cpp", "highlights"), "missing C++ highlight queries")
    for _, fixture in ipairs({ "host.metalcpp", "kernel.metal" }) do
      vim.cmd("edit tests/fixtures/" .. fixture)
      local buf = vim.api.nvim_get_current_buf()
      if fixture == "host.metalcpp" then
        local parser = vim.treesitter.get_parser(buf)
        equal("cpp", parser:lang())
        local tree = assert(parser:parse())[1]
        assert(not tree:root():has_error(), "valid metal-cpp must parse without errors")
        assert(vim.treesitter.highlighter.active[buf], "highlighter did not attach")
        local count = 0
        for _ in vim.treesitter.query.get("cpp", "highlights"):iter_captures(tree:root(), buf) do
          count = count + 1
        end
        assert(count > 0, "no highlight captures")
      else
        equal("metal", vim.b.current_syntax)
        assert(not vim.treesitter.highlighter.active[buf], "C++ highlighting must not override Metal")
        -- A manually attached C++ highlighter is stopped on Metal FileType.
        vim.treesitter.start(buf, "cpp")
        vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
        assert(not vim.treesitter.highlighter.active[buf])
        equal("metal", vim.bo.syntax)
      end
    end
  end)
else
  print("SKIP real parser integration (set TREESITTER_METAL_TEST_RUNTIME)")
end

for _, failure in ipairs(failures) do
  io.stderr:write("FAIL " .. failure .. "\n")
end
print(string.format("%d passed, %d failed", passed, #failures))
vim.cmd(#failures == 0 and "qa!" or "cquit 1")
