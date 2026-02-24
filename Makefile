GO_PATH:=$(shell go env GOPATH)
up: 
	@set -a; [ -f .env ] && . ./.env; set +a; \
	./bin/kanissa up local-ubuntu

down: 
	@set -a; [ -f .env ] && . ./.env; set +a; \
	./bin/kanissa down local-ubuntu


setup:
	$(MAKE) -C ./renderer setup;

render:
	${GO_PATH}/bin/k2 apply --inventory ./k2.inventory.yaml

unrender:
	${GO_PATH}/bin/k2 destroy --inventory ./k2.inventory.yaml
