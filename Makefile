up: 
	@set -a; [ -f .env ] && . ./.env; set +a; \
	./bin/kanissa up local-ubuntu

down: 
	@set -a; [ -f .env ] && . ./.env; set +a; \
	./bin/kanissa down local-ubuntu