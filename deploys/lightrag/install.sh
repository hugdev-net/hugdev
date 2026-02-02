#!/usr/bin/env bash
set -x 

export SETUP_PATH="$(pwd)"
export INSTALL_PATH="/opt/apps/lightrag"

export USER_ID="$(id -u)"
export GROUP_ID="$(id -g)"

mkdir -p $INSTALL_PATH || exit 1

mkdir -p ${INSTALL_PATH}/data/postgresql ${INSTALL_PATH}/data/neo4j ${INSTALL_PATH}/postgresql || exit 1

cp -f ${SETUP_PATH}/init.sql ${INSTALL_PATH}/postgresql/ || exit 1

cd ${SETUP_PATH} && docker compose up -d --wait || exit 1

cd ${INSTALL_PATH} && rm -rf LightRAG && git clone https://github.com/HKUDS/LightRAG.git || exit 1

cp ${SETUP_PATH}/lightrag.env ${INSTALL_PATH}/LightRAG/.env || exit 1 

cd ${INSTALL_PATH}/LightRAG && docker compose up -d --wait || exit 1

docker logs lightrag

echo "LightRAG installed. docker logs -f lightrag"

