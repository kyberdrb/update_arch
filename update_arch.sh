#!/bin/sh

set -e
set -x

REPO_DIR="$(dirname "$(readlink --canonicalize "$0")")"
CUSTOM_LOG_DIR="${REPO_DIR}/logs"
date "+%Y_%m_%d-%H_%M_%S" > "${CUSTOM_LOG_DIR}/update_arch-last_time_the_update_was_initiated.log"
BACKUP_TIME_AND_DATE=$(cat "${CUSTOM_LOG_DIR}/update_arch-last_time_the_update_was_initiated.log")

"${REPO_DIR}/update_arch-worker.sh" 2>&1 | tee "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}.log"

