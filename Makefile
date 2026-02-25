install:
	@./install

step:
	@./install -c "steps/$(STEP).yaml"

update:
	@./install -c steps/01-bootstrap.yaml
	@brew update && brew upgrade
	@sheldon lock --update
	@git submodule update --remote

clean:
	@brew cleanup
	@sheldon cache clear

all: install

.PHONY: install step update clean all
