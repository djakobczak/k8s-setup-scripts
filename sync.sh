#!/bin/bash
set -ux 

ENV_PATH=".config"

if [ -f "${ENV_PATH}" ]; then
    echo "Read ${ENV_PATH}"
    export $(grep -v '^#' ${ENV_PATH} | xargs)
fi

: "${SRC_DIR:="src"}"
: "${DST_DIR:="/home/${K8S_USER}/k8s_scripts"}"

rsync -a "${SRC_DIR}" "${K8S_USER}@${K8S_HOST}:${DST_DIR}"
