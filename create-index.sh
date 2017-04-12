#!/bin/sh
# Usage HOST=http://... ./create-index.sh <indexname (default: datacite)>

HOST=${HOST:-http://localhost:9200}
INDEX=${1:-datacite}

if [[ -n "$FORCE" ]]; then
    echo "Trying to delete old index!"
    curl -XDELETE $HOST/$INDEX?format=yaml
fi

echo "\nCreating new index using metadata-index-settings.yml"

curl -XPUT $HOST/$INDEX?pretty=true -d @metadata-index-settings.yml --header "Content-Type: application/x-yaml"
