#!/bin/sh

#set -e
set -x

SKIP_UPDATING_ALL_IGNORED_PACKAGES=$1

REPO_DIR="$(dirname "$(readlink --canonicalize "$0")")"
CUSTOM_LOG_DIR="${REPO_DIR}/logs"
date "+%Y_%m_%d-%H_%M_%S" > "${CUSTOM_LOG_DIR}/update_arch-last_time_the_update_was_initiated.log"
BACKUP_TIME_AND_DATE=$(cat "${CUSTOM_LOG_DIR}/update_arch-last_time_the_update_was_initiated.log")

"${REPO_DIR}/update_arch-prepare.sh" "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}.log" 2>&1 | tee "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}.log"

"${REPO_DIR}/update_arch-worker.sh" "${SKIP_UPDATING_ALL_IGNORED_PACKAGES}" 2>&1 | tee --append "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}.log"

"${REPO_DIR}/update_arch-finalize.sh" "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}.log" 2>&1 | tee --append "${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}.log"

echo "All logs can be found at: '${CUSTOM_LOG_DIR}/update_arch-${BACKUP_TIME_AND_DATE}.log'"

set +x

