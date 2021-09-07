#!/bin/bash

docker-compose up -d

sleep 5
echo -ne "\n\nWaiting for the systems to be ready.."
function test_systems_available {
  COUNTER=0
  until $(curl --output /dev/null --silent --head --fail http://localhost:$1); do
      printf '.'
      sleep 2
      let COUNTER+=1
      if [[ $COUNTER -gt 30 ]]; then
        MSG="\nWARNING: Could not reach configured kafka system on http://localhost:$1 \nNote: This script requires curl.\n"

          if [[ "$OSTYPE" == "darwin"* ]]; then
            MSG+="\nIf using OSX please try reconfiguring Docker and increasing RAM and CPU. Then restart and try again.\n\n"
          fi

        echo -e $MSG
        clean_up "$MSG"
        exit 1
      fi
  done
}

test_systems_available 8083

echo -e "\nAdding MongoDB Kafka Sink Connector for the 'users' topic into the 'test.users' collection:"
curl -X POST -H "Content-Type: application/json" --data "@./connector.json" http://localhost:8083/connectors 

echo '{ "id": 123, "name": "Bob" }' | kafka-console-producer --broker-list localhost:29092 --topic users

docker-compose exec mongo /usr/bin/mongo --eval 'db.users.find()'

# this should update the "Bob" record with a new field
echo '{ "id": 123, "name": "Bob", "admin": false }' | kafka-console-producer --broker-list localhost:29092 --topic users

docker-compose exec mongo /usr/bin/mongo --eval 'db.users.find()'