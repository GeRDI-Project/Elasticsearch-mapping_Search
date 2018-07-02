#!/bin/sh

# treat unset variables as an error when substituting
set -u

HOST=${HOST:-http://localhost:9200}
ALIAS=${ALIAS:-gerdi}

echo "Checking if an old index exists in order to replace it"

CreateNewIndex() {
  TARGETINDEX=$ALIAS-$(date +"%d%m%y-%H%M")
  js-yaml metadata-index-settings.yml | cur -s -XPUT "$HOST/$TARGETINDEX?format=yaml" -d @- --header "Content-Type: application/json"
  curl -s -XPOST "$HOST/_aliases?format=yaml" -d '{
    "actions": [
    { "add": { "index": "'$TARGETINDEX'", "alias": "'$ALIAS'" } }
    ]
  }' --header "Content-Type: application/json"
  echo "Index created"
}

UpdateIndex() {
  SOURCEINDEX=$(curl -s "$HOST/$ALIAS" | sed -nE 's/.*"provided_name":"(.*)"\,"creation_date.*/\1/p')
  TARGETINDEX=$ALIAS-$(date +"%d%m%y-%H%M")
  js-yaml metadata-index-settings.yml | curl -s -XPUT "$HOST/$TARGETINDEX?format=yaml" -d @- --header "Content-Type: application/json"
  curl -s -XPOST "$HOST/_reindex?format=yaml" -d '{
    "source": {
      "index": "'$SOURCEINDEX'"
    },
    "dest": {
      "index": "'$TARGETINDEX'"
    }
  }' --header "Content-Type: application/json"
  curl -s -XPOST "$HOST/_aliases?format=yaml" -d '{
    "actions": [
    { "add": { "index": "'$TARGETINDEX'", "alias": "'$ALIAS'" } },
    { "remove_index": { "index": "'$SOURCEINDEX'" } }
    ]
  }' --header "Content-Type: application/json"
  echo "Index updated"
}

# Update index on start
SOURCEINDEX=$(curl -s "$HOST/$ALIAS" | sed -nE 's/.*"provided_name":"(.*)"\,"creation_date.*/\1/p')
if [ "$SOURCEINDEX" != "" ]; then
  echo "Updating to a new schema"
  UpdateIndex
else
  echo "Existing index not found. Creating new index."
  CreateNewIndex
fi

# Check for crashed index
while true
do
  sleep 300
  echo "Checking for lost index"
  NOTFOUND=$(curl -s "$HOST/$ALIAS" | grep index_not_found)
  if [ "$NOTFOUND" != "" ]; then
    echo "Index seems to be lost. Creating index again"
    CreateNewIndex
  else
    echo "Index exists. Will recheck in 5 minutes"
  fi
done
