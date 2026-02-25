GO_PATH:=$(shell go env GOPATH)
K2_LATEST_VERSION := $(shell command -v jq >/dev/null 2>&1 && curl --silent "https://api.github.com/repos/tuxounet/k2/tags" | jq -r '.[0].name' || echo "latest")


setup:
	@command -v jq >/dev/null 2>&1 || { echo "Erreur: jq est requis. Lancez 'make setup' depuis la racine du projet."; exit 1; }
	@echo "Installing K2"
	go install github.com/tuxounet/k2@${K2_LATEST_VERSION}
 
render: 
	${GO_PATH}/bin/k2  apply --inventory ./k2.inventory.yaml

unrender: 
	${GO_PATH}/bin/k2  destroy --inventory ./k2.inventory.yaml


 