#! /bin/bash

# If first arg is bash, we'll just execute directly
if [ "$1" == "bash" ]; then
    exec "$@"
    exit 0
fi

# If no env variable set, get from command line
if [ "$OPT_ARGUMENTS" == "" ]; then
    export OPT_ARGUMENTS="$*"
fi

# Init the repo
restic -r "$BACKUP_DEST" snapshots || restic -r "$BACKUP_DEST" init

# If set to restore on start, restore if the data volume is empty
if [ "$RESTORE_ON_EMPTY_START" == "true" ]; then
    /scripts/cron-exec.sh /scripts/restore.sh latest
    exit 0
fi

# Unless explicitly skipping, take a backup on startup
if [ "$SKIP_ON_START" != "true" ]; then
    /scripts/cron-exec.sh /scripts/backup.sh
fi

if [ -n "$CRON_SCHEDULE" ]; then
    # Export the environment to a file so it can be loaded from cron
    env | sed 's/^\(.*\)=\(.*\)$/export \1="\2"/g' > /env.sh
    # Remove some vars we don't want to keep
    sed -i '/\(HOSTNAME\|affinity\|SHLVL\|PWD\)/d' /env.sh

    # Use bash for cron
    echo "SHELL=/bin/bash" > /crontab.conf

    # Schedule the backups
    echo "$CRON_SCHEDULE /scripts/cron-exec.sh /scripts/backup.sh" >> /crontab.conf
    echo "Backups scheduled as $CRON_SCHEDULE"

    if [ -n "$VERIFY_CRON_SCHEDULE" ]; then
        echo "$VERIFY_CRON_SCHEDULE /scripts/cron-exec.sh /scripts/verify.sh" >> /crontab.conf
        echo "Verify scheduled as $VERIFY_CRON_SCHEDULE"
    fi

    # Add to crontab
    crontab /crontab.conf

    # List crontabs
    crontab -l

    echo "Starting cron..."
    crond

    touch /cron.log
    tail -f /cron.log
fi
