_prepare:
	@git submodule update --init --recursive

install:
	@make _prepare
	@./install

update:
	@make _prepare
	@brew update && brew upgrade
	@sheldon lock --update
	@git submodule update --remote

clean:
	@brew cleanup
	@sheldon cache clear

all: install

.PHONY: _prepare install update clean all
