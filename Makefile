_prepare:
	@git submodule update --init --recursive

bootstrap:
	@./install -c config/bootstrap.conf.yml

dotfiles:
	@./install -c config/dotfiles.conf.yml

packages:
	@./install -c config/packages.conf.yml

vscode:
	@./install -c config/vscode.conf.yml

python:
	@./install -c config/python.conf.yml

update:
	@make _prepare
	@./install -c config/update.conf.yml

all: _prepare bootstrap dotfiles packages python vscode
