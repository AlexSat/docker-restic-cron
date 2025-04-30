#! /bin/bash
set -e
set -x

restore_snapshot="$1"

# Run pre-restore scripts
for f in /scripts/restore/before/*; do
    if [ -f "$f" ] && [ -x "$f" ]; then
        bash "$f"
    fi
done

echo "Cleanup restoring directory"
# Remove all content except mountpoint directories itself
find $PATH_TO_BACKUP -depth -mindepth 1 -print0 | while IFS= read -r -d '' item; do
    if [ -d "$item" ] && mountpoint -q "$item"; then
        echo "Skip mountpoint: $item"
    else
        rm -rv "$item"
    fi
done
echo "Cleanup completed"

# shellcheck disable=SC2086
restic \
    -r "$BACKUP_DEST" \
    $OPT_ARGUMENTS \
    restore \
    "$restore_snapshot" \
    -t /

# Run post-restore scripts
for f in /scripts/restore/after/*; do
    if [ -f "$f" ] && [ -x "$f" ]; then
        bash "$f"
    fi
done
