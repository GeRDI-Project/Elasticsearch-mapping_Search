#!/bin/sh

HOST=${HOST:-http://localhost:9200}
ALIAS=${ALIAS:-gerdi}

echo "Checking if an old index exists in order to replace it"
SOURCEINDEX=$(curl -s $HOST/$ALIAS | sed -nE 's/.*"provided_name":"(.*)"\,"creation_date.*/\1/p')
TARGETINDEX=$ALIAS-$(date +"%d%m%y-%H%M")

if [ "$SOURCEINDEX" != "" ]; then
  echo "Updating to a new schema"
  js-yaml metadata-index-settings.yml | curl -XPUT $HOST/$TARGETINDEX?format=yaml -d @- --header "Content-Type: application/json"
  curl -XPOST $HOST/_aliases -d '{
    "actions": [
    { "add": { "index": "'$TARGETINDEX'", "alias": "'$ALIAS'" } },
    { "remove_index": { "index": "'$SOURCEINDEX'" } }
    ]
  }' --header "Content-Type: application/json"
else
  echo "Existing index not found. Creating new index."
  js-yaml metadata-index-settings.yml | curl -XPUT $HOST/$TARGETINDEX?format=yaml -d @- --header "Content-Type: application/json"
  curl -XPOST $HOST/_aliases -d '{
    "actions": [
    { "add": { "index": "'$TARGETINDEX'", "alias": "'$ALIAS'" } }
    ]
  }' --header "Content-Type: application/json"
fi


while true
do
  sleep 5 # set to 300 after debugging
  echo "Checking for lost index"
  NOTFOUND=$(curl -s $HOST/$ALIAS | grep index_not_found)
  if [ "$NOTFOUND" != "" ]; then
    echo "Index seems to be lost. Creating index again"
    TARGETINDEX=$ALIAS-$(date +"%d%m%y-%H%M")
    js-yaml metadata-index-settings.yml | curl -XPUT $HOST/$TARGETINDEX?format=yaml -d @- --header "Content-Type: application/json"
    curl -XPOST $HOST/_aliases -d '{
      "actions": [
      { "add": { "index": "'$TARGETINDEX'", "alias": "'$ALIAS'" } }
      ]
    }' --header "Content-Type: application/json"
  else
    echo "Index exists. Will recheck in 5 minutes"
  fi
done
