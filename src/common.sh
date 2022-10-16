#!/bin/bash

read_env() {
    local env_path="${1:?}"
    if [ -f "${env_path}" ]; then
        echo "Read ${env_path}"
        source "${env_path}"
        # export $(grep -v '^#' ${env_path} | xargs)  # problem with arrays
    fi
}