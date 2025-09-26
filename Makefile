_prepare:
	@git submodule update --init --recursive

install:
	@make _prepare
	@./install

update:
	@make _prepare
	@brew update && brew upgrade

all: install
