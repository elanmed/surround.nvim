.PHONY: dev clean test lint format docs update-submodules

dev:
	mkdir -p ~/.local/share/nvim/site/pack/dev/start/surround.nvim
	stow -d .. -t ~/.local/share/nvim/site/pack/dev/start/surround.nvim surround.nvim

clean:
	rm -rf ~/.local/share/nvim/site/pack/dev

test:
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

lint:
	# https://luals.github.io/#install
	VIMRUNTIME="$$(nvim --headless --clean -c 'lua io.write(vim.env.VIMRUNTIME)' -c 'qa')" lua-language-server --check=./lua --checklevel=Warning --configpath=$(CURDIR)/.luarc.json
	VIMRUNTIME="$$(nvim --headless --clean -c 'lua io.write(vim.env.VIMRUNTIME)' -c 'qa')" lua-language-server --check=./tests --checklevel=Warning --configpath=$(CURDIR)/.luarc.json

format:
	# https://github.com/JohnnyMorganz/StyLua#usage
	stylua .

update-submodules:
	git submodule update --init --recursive --remote

docs:
	./deps/ts-vimdoc.nvim/scripts/docgen.sh README.md doc/surround.txt surround
	nvim --headless -c "helptags doc/" -c "qa"

deploy: update-submodules test lint format docs
