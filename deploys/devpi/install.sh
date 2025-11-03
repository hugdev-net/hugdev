#!/usr/bin/env bash

if [ "$1" == 'compose' ]; then
  docker compose build
  docker compose up -d
  docker compose ps
  docker compose logs -f
else
  docker build -t devpi-server .
  docker run -d  --name devpi  -p 3141:3141  -v /data/devpi/files:/app/devpi/server/+files devpi-server
fi
