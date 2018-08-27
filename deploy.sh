#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
if [[ ! -z ${DEBUG_MODE+x} ]]; then
    set -o xtrace
    set -o functrace
fi

ENV_FILE=$(mktemp)

function cleanup_before_exit () {
    rm "$ENV_FILE"
}

trap cleanup_before_exit EXIT

# Base directory on the server for docker containers
DIR=/opt/docker

cd "$DIR"

# Get the latest changes from github
git pull

# Get parameters from AWS SSM Parameter Store and set variabes based on their names.
aws ssm get-parameters-by-path --path / --with-decryption --recursive | jq -r '.Parameters[] | [.Name,.Value] | @tsv' |
    while IFS=$'\t' read -r PARAM VALUE; do
        NAME=$(echo "$PARAM" | sed 's/^.\{1\}//' | sed 's#/#_#')
        echo "export $NAME='$VALUE'" >> "$ENV_FILE"
    done

# Make the output folder if it doesn't exost
mkdir -p "$DIR/_env"

source "$ENV_FILE"

# Render all of the environment variable templates
for INPUT_FILE in _templates/*.env; do
    OUTPUT_FILENAME="$DIR/_env/$(basename "$INPUT_FILE")"
    envsubst < "$INPUT_FILE" > "$OUTPUT_FILENAME"
done

# Render the docker-compose template
envsubst < _templates/docker-compose.tmpl.yaml > "$DIR/docker-compose.yaml"

# Deploy all the things!
docker-compose up --detach --remove-orphans
