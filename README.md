# tree-sitter-metal

A tiny Neovim runtime plugin for Metal Shading Language (`.metal`) and
metal-cpp files.

- Shaders (`.metal`) use a bundled syntax file covering Metal Shading Language
  4.1: shader stages, address spaces, scalar/vector/matrix/texture/ray tracing/
  tensor types, `[[attributes]]` (including multi-line and future ones), scoped
  enum values, `h`/`bf` literal suffixes and built-in macros. It needs no parser
  or SDK. The C++ Tree-sitter parser is never attached to shaders, because it
  produces parse errors on Metal constructs such as `device float*`.
- Host-side metal-cpp code is ordinary C++ and uses the maintained `cpp`
  Tree-sitter parser.

This plugin starts highlighting only. Folds, motions, and text objects require
their own configuration and queries. For an LSP server see below.

## LazyVim

Add this to `lua/plugins/tree-sitter-metal.lua`:

```lua
return {
  {
    "willinki/tree-sitter-metal",
    lazy = false, -- register filetypes before the first file is opened
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if type(opts.ensure_installed) == "table"
        and not vim.tbl_contains(opts.ensure_installed, "cpp") then
        table.insert(opts.ensure_installed, "cpp")
      end
    end,
  },
}
```

If your `nvim-treesitter` configuration does not use `ensure_installed`, install
the C++ parser once instead:

```vim
:TSInstall cpp
```

The current `nvim-treesitter` main branch also supports:

```lua
require("nvim-treesitter").install({ "cpp" })
```

## Filetypes

| Files | Filetype | Highlighting |
| --- | --- | --- |
| `*.metal` | `metal` | bundled `syntax/metal.vim` |
| `*.metalcpp`, `*.metalpp`, `*.metal-cpp` | `metal_cpp` | Tree-sitter `cpp` |
| `*.metal.hpp`, `*.metal.h` | `metal_cpp` | Tree-sitter `cpp` |

Ordinary `.cpp`, `.hpp`, and `.h` files keep Neovim's existing detection (which
can depend on your configuration). Apple's metal-cpp headers and host code are
ordinary C++ and already use the C++ parser. The extra extensions above are
optional conventions, not official metal-cpp extensions. For another filename, set
`vim.bo.filetype = "metal_cpp"` or add a project-local `vim.filetype.add()`
rule.

Both custom filetypes inherit Neovim's C++ comment and indentation settings.
They do not automatically inherit C++ LSP configurations; this plugin does not
configure a language server.

## Troubleshooting

If starting the parser fails for a metal-cpp buffer, the plugin reports the
error once per distinct message. Install `cpp` with `:TSInstall cpp`, wait for
installation to finish, then reopen the buffer. A parser alone does not supply
highlight queries; `nvim-treesitter` supplies both. `:InspectTree` shows the
C++ parse tree for metal-cpp buffers. Shader (`.metal`) buffers use no parser,
so a global `vim.treesitter.start()` autocmd fails on them the same way it does
for any filetype without a parser; the bundled syntax highlighting still applies.

Load this plugin at startup (`lazy = false`). Deferring it to `ft = "metal"`
can prevent its own filetype detection from ever loading. No `setup()` or
`opts = {}` is needed.

## Tests

Run the dependency-free regression suite from the repository root:

```sh
nvim --clean -i NONE --headless -l tests/run.lua
```

For real parsing and highlighting checks, set `TREESITTER_METAL_TEST_RUNTIME`
to a runtime directory containing `parser/cpp.so` and C++/C highlight queries.
The CI workflow builds the upstream parser and runs both suites. Shader tests
(`tests/highlights.lua`) check the syntax groups assigned to Metal tokens.

## Requirements

- Neovim 0.9+
- For metal-cpp files only: a C++ Tree-sitter parser and highlight queries
  (normally provided by `nvim-treesitter`; its own version requirements also
  apply)

## License

[MIT](LICENSE)

## LSP and Autocomplete

```lua
-- metal-analyzer: LSP for Apple Metal Shading Language
-- https://github.com/computer-graphics-tools/metal-analyzer
--
-- Binary is installed manually (no Mason package yet), e.g. in ~/.local/bin.
-- Diagnostics require `xcrun metal` (full Xcode + MetalToolchain component);
-- formatting requires clang-format.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        metal_analyzer = {
          mason = false, -- not available through mason-lspconfig
          cmd = { "metal-analyzer" }, -- add "--verbose", "--log-messages" to debug (~/.metal-analyzer/)
          filetypes = { "metal" }, -- filetype registered by willinki/tree-sitter-metal
          root_markers = { "metalfmt.toml", ".clang-format", "Package.swift", ".git" },
          -- Settings are read from initializationOptions (camelCase keys),
          -- either flattened like this or scoped under "metal-analyzer".
          init_options = {
            compiler = {
              platform = "macos",
              includePaths = {},
              extraFlags = {},
            },
            diagnostics = { onType = true, onSave = true, scope = "openFiles" },
            formatting = { enable = true },
            indexing = { enable = true },
          },
        },
      },
    },
  },
}
```
