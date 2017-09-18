#!/bin/sh
# Usage HOST=http://... ./create-index.sh <indexname (default: datacite)>
# REQUIREMENTS:
# curl
# nodejs 6+
# run: npm install -g js-yaml@3.8.3

HOST=${HOST:-http://localhost:9200}
INDEX=${1:-gerdi}

if [ -n "$FORCE" ]; then
    echo "Trying to delete old index!"
    curl -XDELETE $HOST/$INDEX?format=yaml
fi

echo "\nCreating new index using metadata-index-settings.yml"

js-yaml metadata-index-settings.yml | curl -XPUT $HOST/$INDEX?format=yaml -d @- --header "Content-Type: application/x-yaml"
