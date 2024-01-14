#! /bin/bash
source /scripts/utils/utils.sh
set -e
set -x

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

# Run post-backup scripts
for f in /scripts/backup/after/*; do
    if [ -f "$f" ] && [ -x "$f" ]; then
        bash "$f" && rc=$? || rc=$?
	echo exitcode: $rc
        exitCodesSum=$exitCodesSum+$rc
    fi
done

[[ pushMetricsEnabled -eq 1 ]] && pushBackupFinishMetrics $exitCodesSum "${BACKUP_METRICS_SYSTEM_NAME}" "${BACKUP_METRICS_PUSHGATEWAY_URL}"
