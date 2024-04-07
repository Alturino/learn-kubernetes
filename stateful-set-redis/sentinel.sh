#!/bin/bash
set -ex
while ! ping -c 1 redis-0.redis; do
  echo 'Waiting for server'
  sleep 1
done
