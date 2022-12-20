#! /bin/bash
set -e
set -x

# Run pre-backup scripts
for f in /scripts/backup/before/*; do
    if [ -f "$f" ] && [ -x "$f" ]; then
        bash "$f" && rc=$? || rc=$?
	echo exitcode: $rc
    fi
done

# shellcheck disable=SC2086
restic \
    -r "$BACKUP_DEST" \
    $OPT_ARGUMENTS \
    backup \
    "$PATH_TO_BACKUP" && rc=$? || rc=$?
echo exitcode: $rc

if [ -n "$CLEANUP_COMMAND" ]; then
    # Clean up old snapshots via provided policy
    # shellcheck disable=SC2086
    restic \
        -r "$BACKUP_DEST" \
        forget \
        $CLEANUP_COMMAND --group-by '' && rc=$? || rc=$?
    echo exitcode: $rc

    # Verify that nothing is corrupted
    restic check -r "$BACKUP_DEST" && rc=$? || rc=$?
    echo exitcode: $rc
fi

# Run post-backup scripts
for f in /scripts/backup/after/*; do
    if [ -f "$f" ] && [ -x "$f" ]; then
        bash "$f" && rc=$? || rc=$?
	echo exitcode: $rc
    fi
done
