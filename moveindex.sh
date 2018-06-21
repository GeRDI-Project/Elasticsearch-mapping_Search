curl -v -XPOST http://localhost:9200/_reindex -d '{
  "source": {
    "index": "'$SOURCEINDEX'"
  },
  "dest": {
    "index": "'$TARGETINDEX'"
  }
}' --header "Content-Type: application/json"
curl -XPOST http://localhost:9200/_aliases -d '{
  "actions": [
    { "add": { "index": "'$TARGETINDEX'", "alias": "gerdi" } },
    { "remove_index": { "index": "'$SOURCEINDEX'" } }
  ]
}' --header "Content-Type: application/json"
