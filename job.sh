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

source ./functions.sh

HOST=${HOST:-http://localhost:9200}
ALIAS=${ALIAS:-gerdi}

echo "Checking if an old index exists in order to replace it"

# Update index on start
SOURCEINDEX=$(curl -s "$HOST/$ALIAS" | sed -nE 's/.*"provided_name":"(.*)"\,"creation_date.*/\1/p') # curl returns a document describing the concrete index, or a missing index exception
if [ "$?" != 0 ]; then
  echo "ERROR: Cannot connect to "$HOST"/"$ALIAS". Exiting now"
  exit 1
fi
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
  PAYLOAD=$(curl -s "$HOST/$ALIAS")
  if [ "$?" != 0 ]; then
    echo "ERROR: Cannot connect to "$HOST"/"$ALIAS"." >&2
    continue # Don't exit, because this may be a temporal outage
  fi
  NOTFOUND=$(echo "$PAYLOAD" | grep index_not_found)
  if [ "$NOTFOUND" != "" ]; then
    echo "Index seems to be lost. Creating index again"
    CreateNewIndex
  else
    echo "Index exists. Will recheck in 5 minutes"
  fi
done
