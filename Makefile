GO_PATH:=$(shell go env GOPATH)
STACK ?= off-grid

up:
	@./anissa/bin/anissa up $(STACK)

down:
	@./anissa/bin/anissa down $(STACK)

restart:
	@./anissa/bin/anissa restart $(STACK)

status:
	@./anissa/bin/anissa status $(STACK)

logs:
	@./anissa/bin/anissa logs $(STACK)

healthcheck:
	@./anissa/bin/anissa healthcheck $(STACK)

shell:
	@./anissa/bin/anissa shell $(STACK)

stacks:
	@./anissa/bin/anissa stacks

layers:
	@./anissa/bin/anissa layers

setup:
	$(MAKE) -C ./renderer setup;

render:
	${GO_PATH}/bin/k2 apply --inventory ./k2.inventory.yaml

unrender:
	${GO_PATH}/bin/k2 destroy --inventory ./k2.inventory.yaml
