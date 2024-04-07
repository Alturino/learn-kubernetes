#!/bin/bash
set -ex
apt update && apt install iputils-ping -y

until ping -c 1 "$HOSTNAME".mongo; do
  echo "waiting for DNS (${HOSTNAME}.mongo)..."
  sleep 2
done

until /usr/bin/mongo --eval 'printjson(db.serverStatus())'; do
  echo "connecting to local mongo..."
  sleep 2
done
echo "connected to local"

HOST=mongo-0.mongo:27017
until /usr/bin/mongo --host="$HOST" --eval 'printjson(db.sererStatus())'; do
  echo "connecting to remote mongo..."
  sleep 2
done
echo "connected to remote"

if [[ "$HOSTNAME" == 'mongo-0' ]]; then
  echo "initializing replica set"
  /usr/bin/mongo --eval="printjson(rs.initiate({'_id': 'rs0', 'members': [{'_id': 0, 'host': '${HOST}'}]}))"
else
  until /usr/bin/mongo --host="$HOST" --eval="printjson(rs.status())" | grep -v "no replset config has been received"; do
    echo "waiting for replication set initialization"
    sleep 2
  done
  echo "adding self to mongo-0"
  /usr/bin/mongo --host="$HOST" --eval="printjson(rs.add('${HOSTNAME}.mongo'))"
fi
echo "initialized"

while true; do
  sleep 3600
done