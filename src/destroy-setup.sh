#!/bin/bash
set -u

. common.sh
. logging.sh
read_env ".env"

log_info "Removing ${MASTER0_NAME}"
./destroy.sh "${MASTER0_NAME}"
for worker_name in "${WORKERS_NAMES[@]}"; do
    log_info "Removing ${worker_name}"
    ./destroy.sh "${worker_name}"
done
