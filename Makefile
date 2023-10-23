_prepare:
	@git submodule update --init --recursive

dotfiles: 
	@./install -c config/dotfiles.conf.yml

#macos_settings:
#	@./install -c etc/macos/settings.sh

#macos_dock:
#	@./install -c etc/macos/dock.sh

bootstrap:
	@./install -c config/zsh.conf.yml

packages:
	@./install -c config/packages.conf.yml

vscode:
	@./install -c config/vscode.conf.yml

update:
	@make _prepare
	@./install -c config/update.conf.yml

all: _prepare bootstrap dotfiles
