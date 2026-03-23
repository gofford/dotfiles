bootstrap:
	@./install \
		steps/01-bootstrap.yaml \
		steps/02-brew-core.yaml \
		steps/03-brew-casks.yaml \
		steps/04-brew-mas.yaml \
		steps/08-brew-extensions.yaml

apply:
	@./install \
		steps/05-shell.yaml \
		steps/06-dev.yaml \
		steps/07-system.yaml

install: bootstrap apply

step:
	@./install -c "steps/$(STEP).yaml"

link: apply

dock:
	@./install -c steps/09-dock.yaml

update:
	@git pull --ff-only
	@$(MAKE) apply

upgrade:
	@brew update && brew upgrade
	@sheldon lock --update
	@git submodule update --remote
	@$(MAKE) apply

doctor:
	@scripts/doctor.sh

clean:
	@brew cleanup
	@sheldon cache clear

all: install

.PHONY: bootstrap apply install step link dock update upgrade doctor clean all
