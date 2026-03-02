install:
	@./install

step:
	@./install -c "steps/$(STEP).yaml"

link:
	@./install -c steps/05-shell.yaml
	@./install -c steps/06-dev.yaml
	@./install -c steps/07-system.yaml

dock:
	@./install -c steps/09-dock.yaml

update:
	@./install -c steps/01-bootstrap.yaml
	@brew update && brew upgrade
	@sheldon lock --update
	@git submodule update --remote

clean:
	@brew cleanup
	@sheldon cache clear

all: install

.PHONY: install step link dock update clean all
