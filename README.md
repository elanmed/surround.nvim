# `surround.nvim`

A minimal [`vim-surround`](https://github.com/tpope/vim-surround)

### Features

- 1 source file (~300 lines), 1 test file (~600 lines)
- Triggers hidden visual selections to find pair positions
  - Leverages native vim pair matching as opposed to complex regexes, string parsing, treesitter walking, etc
- Supports `ds`, `cs`, `ys`, and `S` (visual mode) keymaps
  - Normal mode keymaps are dot-repeatable

## Default keymaps

The plugin defines the following default mappings:

| Mapping            | Action                                              |
| ------------------ | --------------------------------------------------- |
| `ds{char}`         | Delete the surrounding pair identified by `{char}`  |
| `cs{old}{new}`     | Change the surrounding pair `{old}` to `{new}`      |
| `ys{motion}{char}` | Add `{char}` around the text selected by `{motion}` |
| Visual `S{char}`   | Add `{char}` around the visual selection            |

The supported pair characters are `(` / `)`, `[` / `]`, `{` / `}`, `<` / `>`, single quote, double quote, backtick, and space. Either side of bracket pairs can be entered.

Pressing `Esc` at a character prompt cancels the operation.

## Similar plugins

- [`vim-surround`](https://github.com/tpope/vim-surround)
- [`mini.surround`](https://github.com/nvim-mini/mini.surround)
- [`nvim-surround`](https://github.com/kylechui/nvim-surround)
