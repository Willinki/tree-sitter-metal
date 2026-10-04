# treesitter-metal

A tiny Neovim runtime plugin for Metal Shading Language (`.metal`) and
metal-cpp files. It treats both as C++ for Tree-sitter, reusing the maintained
`cpp` parser rather than shipping a duplicate parser binary or grammar.

This is deliberately an integration layer, not a complete Metal grammar.
Metal-specific constructs (including address-space qualifiers such as `device`)
may produce parse errors. Standard C++ syntax is supported; Metal highlighting
is best-effort. This plugin starts highlighting only. Folds, motions, and text
objects require their own configuration and queries.

## LazyVim

Add this to `lua/plugins/treesitter-metal.lua`, replacing `YOUR_GITHUB_USER`
after publishing this repository:

```lua
return {
  {
    "YOUR_GITHUB_USER/treesitter-metal",
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

| Files | Filetype | Tree-sitter parser |
| --- | --- | --- |
| `*.metal` | `metal` | `cpp` |
| `*.metalcpp`, `*.metalpp`, `*.metal-cpp` | `metal_cpp` | `cpp` |
| `*.metal.hpp`, `*.metal.h` | `metal_cpp` | `cpp` |

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

If starting the parser fails, the plugin reports the error once per distinct
message. Install `cpp` with `:TSInstall cpp`, wait for installation to finish,
then reopen the buffer. A parser alone does not supply highlight queries;
`nvim-treesitter` supplies both. `:InspectTree` shows the C++ parse tree.

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
The CI workflow builds the upstream parser and runs both suites. Metal tests
check highlighting, not error-free parsing of the Metal language.

## Publish

Create an empty GitHub repository named `treesitter-metal`, add it as `origin`,
then push `main`. The plugin has no build step and no bundled binaries.

## Requirements

- Neovim 0.9+
- A C++ Tree-sitter parser and highlight queries (normally provided by
  `nvim-treesitter`; its own version requirements also apply)

## License

[MIT](LICENSE)
