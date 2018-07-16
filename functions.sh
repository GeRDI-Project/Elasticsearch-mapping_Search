#!/bin/bash

# Copyright © 2018 Nelson Tavares de Sousa (http://www.gerdi-project.de/)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# treat unset variables as an error when substituting
set -u
# If anything in the pipe fails, return the last non-zero exit code as overall exit code
set -o pipefail

CreateNewIndex() {
  TARGETINDEX=$ALIAS-$(date +"%d%m%y-%H%M")
  js-yaml metadata-index-settings.yml | curl -s -XPUT "$HOST/$TARGETINDEX?format=yaml" -d @- --header "Content-Type: application/json"
  curl -s -XPOST "$HOST/_aliases?format=yaml" -d '{
    "actions": [
    { "add": { "index": "'$TARGETINDEX'", "alias": "'$ALIAS'" } }
    ]
  }' --header "Content-Type: application/json"
  echo "Index created"
}

UpdateIndex() {
  SOURCEINDEX=$(curl -s "$HOST/$ALIAS" | sed -nE 's/.*"provided_name":"(.*)"\,"creation_date.*/\1/p') # curl returns a document describing the concrete index, or a missing index exception
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
