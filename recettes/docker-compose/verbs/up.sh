
BASE_PATH=$(dirname "$0")
PARENT_PATH=$(dirname "$BASE_PATH")

docker compose -f "${PARENT_PATH}/compose.yml"  --project-name {{ .name }}  up -d --build