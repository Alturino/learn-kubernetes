#!/bin/bash
set -ex

if [[ "$HOSTNAME" == 'postgres-0' ]]; then
  echo "setup primary server"
  mkdir -p /data/archive && chown postgres:postgres /data/archive

  echo "CREATE USER \$REPLICATION_USER REPLICATION LOGIN ENCRYPTED PASSWORD '\$REPLICATION_PASSWORD';" > init.sql

  sed -i "s/\$REPLICATION_USER/${REPLICATION_USER}/g" init.sql
  sed -i "s/\$REPLICATION_PASSWORD/${REPLICATION_PASSWORD}/g" init.sql

  mkdir -p /docker-entrypoint-initdb.d
  cp init.sql /docker-entrypoint-initdb.d/init.sql

  mkdir -p /temp-config
  cp /config/primary.conf /temp-config/postgresql.conf
  cp /config/primary_pg_hba.conf /temp-config/pg_hba.conf

  echo "finised setup primary server"
else
  echo "setup standby server"

  mkdir -p /temp-config
  cp /config/standby.conf /temp-config/postgresql.conf
  cp /config/standby_pg_hba.conf /temp-config/pg_hba.conf

  if [[ -z "$(ls -A "$PGDATA")" ]]; then
    export PGPASSWORD=${REPLICATION_PASSWORD}
    pg_basebackup -h "postgres-0.postgres" -p 5432 -U "$REPLICATION_USER" -D "$PGDATA" -Fp -Xs -R
  fi

  echo "finised setup standby server"
fi
echo "initialized"
