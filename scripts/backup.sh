#! /bin/bash
source /scripts/utils/utils.sh
set -e
set -x

function execBackup {
    # shellcheck disable=SC2086
    restic \
        -r "$BACKUP_DEST" \
        $OPT_ARGUMENTS \
        backup \
        "$PATH_TO_BACKUP" && rc=$? || rc=$?
    echo exitcode: $rc
    exitCodesSum=$exitCodesSum+$rc

    if [ -n "$CLEANUP_COMMAND" ]; then
        # Clean up old snapshots via provided policy
        # shellcheck disable=SC2086
        restic \
            -r "$BACKUP_DEST" \
            forget \
            $CLEANUP_COMMAND --group-by '' && rc=$? || rc=$?
        echo exitcode: $rc
        exitCodesSum=$exitCodesSum+$rc

        # Verify that nothing is corrupted
        restic check -r "$BACKUP_DEST" && rc=$? || rc=$?
        echo exitcode: $rc
        exitCodesSum=$exitCodesSum+$rc
    fi
}

function SnapshotAppDataAndMountToSnapshotPath {
    http_response=$(curl -s -L -w "\n%{http_code}" --data "{\"dataset_name\":\"${DATASET_NAME}\", \"mount_path\":\"${SNAPSHOT_MOUNT_PATH}\"}" --header 'Content-Type: application/json' --request POST ${ZFS_HOST}/api/v1/snapshots 2>&1 && rc=$? || rc=$?)
    echo exitcode: $rc
    exitCodesSum=$exitCodesSum+$rc
    if [ $rc -ne 0 ]; then
        dobackup=0
        return
    fi
    http_code=$(echo "$http_response" | tail -n 1)
    response_body=$(echo "$http_response" | sed '$d')
    if [ $http_code != "201" ]; then
        echo http_code: $http_Code
        rc=1
        echo exitcode: $rc
        exitCodesSum=$exitCodesSum+$rc
        dobackup=0
    fi 
}

function UmountSnapshotAndDeleteIt {
    http_response=$(curl -s -L -w "\n%{http_code}" --data "$response_body" --header 'Content-Type: application/json' --request DELETE ${ZFS_HOST}/api/v1/snapshots 2>&1 && rc=$? || rc=$?)
    echo exitcode: $rc
    exitCodesSum=$exitCodesSum+$rc
    if [ $rc -ne 0 ]; then
        return
    fi
    http_code=$(echo "$http_response" | tail -n 1)
    response_body=$(echo "$http_response" | sed '$d')
    if [ $http_code != "200" ]; then
        echo http_code: $http_Code
        rc=1
        echo exitcode: $rc
        exitCodesSum=$exitCodesSum+$rc
    fi
}

dobackup=1
# To use zfs snapshots we need all environment variables and mountpoint for it
backupWithZfsSnapshot=1
[[ "${USE_ZFS_SNAPSHOT}" -ne "true" ]] && backupWithZfsSnapshot=0
[[ "${DATASET_NAME}" -ne "true" ]] && backupWithZfsSnapshot=0
[[ -z "${SNAPSHOT_MOUNT_PATH}" ]] && backupWithZfsSnapshot=0
mountpoint -q "${SNAPSHOT_MOUNT_PATH}" || backupWithZfsSnapshot=0

# To push backup metrics we need system name and pushgateway url
pushMetricsEnabled=1
[[ -z "${BACKUP_METRICS_PUSHGATEWAY_URL}" ]] && pushMetricsEnabled=0
[[ -z "${BACKUP_METRICS_SYSTEM_NAME}" ]] && pushMetricsEnabled=0

[[ pushMetricsEnabled -eq 1 ]] && pushBackupStartMetrics "${BACKUP_METRICS_SYSTEM_NAME}" "${BACKUP_METRICS_PUSHGATEWAY_URL}"

exitCodesSum=0
# Run pre-backup scripts
for f in /scripts/backup/before/*; do
    if [ -f "$f" ] && [ -x "$f" ]; then
        bash "$f" && rc=$? || rc=$?
	echo exitcode: $rc
	exitCodesSum=$exitCodesSum+$rc
    fi
done

if [[ backupWithZfsSnapshot -eq 0 ]]; then
    execBackup
elif [[ backupWithZfsSnapshot -eq 1 ]]; then
    SnapshotAppDataAndMountToSnapshotPath
fi

# Run post-backup scripts
for f in /scripts/backup/after/*; do
    if [ -f "$f" ] && [ -x "$f" ]; then
        bash "$f" && rc=$? || rc=$?
	echo exitcode: $rc
        exitCodesSum=$exitCodesSum+$rc
    fi
done

if [[ backupWithZfsSnapshot -eq 1 ]]; then
    if [ $dobackup -eq 1 ]; then
        execBackup
        UmountSnapshotAndDeleteIt
    fi
fi

# Напиши функции снепшоттинга - вызов по HTTP твоего сервиса из енвайронмент переменной и удаления снепшота
# Не забудь их коды выходов тоже суммировать

[[ pushMetricsEnabled -eq 1 ]] && pushBackupFinishMetrics $exitCodesSum "${BACKUP_METRICS_SYSTEM_NAME}" "${BACKUP_METRICS_PUSHGATEWAY_URL}"
