# `surround.nvim`

A minimal [`vim-surround`](https://github.com/tpope/vim-surround)

### Features

- 1 source file (~200 LOC), 1 test file (~400 LOC)
- Triggers hidden visual selections to find pair positions
  - Leverages native vim pair matching as opposed to complex regexes, string parsing, treesitter walking, etc
- Supports `ds`, `cs`, `ys`, and `S` (visual mode) keymaps
  - Normal mode keymaps are dot-repeatable

### Similar plugins

- [`vim-surround`](https://github.com/tpope/vim-surround)
- [`mini.surround`](https://github.com/nvim-mini/mini.surround)
- [`nvim-surround`](https://github.com/kylechui/nvim-surround)
