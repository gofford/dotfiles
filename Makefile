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

post:
	@./install -c config/post.conf.yml

#macos_settings:
#	@./install -c etc/macos/settings.sh

#macos_dock:
#	@./install -c etc/macos/dock.sh

update:
	@make _prepare
	@./install -c config/update.conf.yml

all: _prepare bootstrap dotfiles packages vscode post
