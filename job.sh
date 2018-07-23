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
  NOTFOUND=$(curl -s "$HOST/$ALIAS" | grep index_not_found)
  RETVAL=$?
  if [ "$RETVAL" != 0 ]; then
    echo "Index seems to be lost. Creating index again"
    CreateNewIndex
    break # Onto the next loop iteration!
  fi
  if [ "$RETVAL" != 1 ]; then # 0 means the index could not be found and
                              # 1 means the index exists (grep exits with 1 if it cannot find anything and
                              # curl exits with 1 if the scheme is not supported, which is never the case here)
    echo "ERROR: Cannot connect to "$HOST"/"$ALIAS"."
    break # Don't exit, because this may be a temporal outage
  else
    echo "Index exists. Will recheck in 5 minutes"
  fi
done
