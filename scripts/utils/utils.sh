#!/bin/sh

## 
 # @private
 # Executed if a variable is not set or is empty string
 # @param1 - Name of the failed environment variable
 ##
function _check_env_failed {
    echo "Environment variable $1 is not set."
    echo "Environment variables failed, exit 1"
    exit 1
}

## 
 # @private
 # Executed if a variable is setted
 # @param1 - Name of the environment variable
 ##
function _check_env_ok {
    echo "Env var $1 ok."
}

## 
 # Use it to check if environment variables are set
 # @param1      - Name of the context
 # @param2 to ∞ - Environment variables to check
 ##
function check_env {
    echo "Checking environment variables for $1."

    for e_var in "$@"; do
        if [ $e_var = $1 ]; then continue; fi # Jump first arg
        
        # Check if env var is setted, if not raise error
        if [ "${!e_var}" = "" ]; then 
            _check_env_failed $e_var; 
        else 
            _check_env_ok $e_var; 
        fi

    done
    echo "Environment variables ok."
}

## 
 # Use it to enable maintenance mode in Nextcloud
 # @param1      - Container name with Nextcloud instance
 ##
function enable_nextcloud_manitenance_mode {
    echo "Enabling maintenance mode in Nextcloud container: $1"
    docker exec --user www-data $1 php occ maintenance:mode --on
    echo "Maintenance mode has been enabled in Nextcloud container: $1"
}

## 
 # Use it to disable maintenance mode in Nextcloud
 # @param1      - Container name with Nextcloud instance
 ##
function disable_nextcloud_manitenance_mode {
    echo "Disabling maintenance mode in Nextcloud container: $1"
    docker exec --user www-data $1 php occ maintenance:mode --off
    echo "Maintenance mode has been disabled in Nextcloud container: $1"
}

## 
 # Use it to stop docker containers
 # @param1      - array with container names
 ##
function stopDockerContainers {
    echo "Stopping deppendent containers: $1"
    local arrayContainers=
    IFS=' ' read -r -a arrayContainers <<< "$1"
    local min=0
    local max=$(( ${#arrayContainers[@]} ))

    for (( i=$min; i<$max; i++ ))
    do
	echo "Stopping ${arrayContainers[$i]}"
        docker stop "${arrayContainers[$i]}" || true
    done
    echo "Dependent containers stopped: $1"
}

## 
 # Use it to start docker containers
 # @param1      - array with container names
 ##
function startDockerContainers {
    echo "Starting in reverse order deppendent containers: $1"
    local arrayContainers=
    IFS=' ' read -r -a arrayContainers <<< "$1"
    local min=0
    local max=$(( ${#arrayContainers[@]} ))

    for (( i=$max-1; i>=$min; i-- ))
    do
	echo "Starting ${arrayContainers[$i]}"
        docker start "${arrayContainers[$i]}" || true
    done
    echo "Dependent containers started in reverse order: $1"
}

## 
 # Use it to push backup status and finish time to pushgateway
 # @param1      - backup_exit_code ($1 -eq 0 is success, $1 -gt 0 is failed)
 # @param2	- system name
 # @param3	- pushgateway url
 ##
function pushBackupFinishMetrics {
    if [[ $1 -eq 0 ]]; then
	success=1
	textresult="success"
    else
	success=0
	textresult="failed"
    fi
    udt=$(date +%s)
    echo "Pushing backup status for system=$2: $textresult (ts:$udt)"
    printf "backup_success_bool $success\nbackup_latest_finish_unix_timestamp $udt\n" | curl --data-binary @- $3/metrics/job/backup/system/$( printf %s "$2"|jq -sRr @uri )
}

## 
 # Use it to push backup start time to pushgateway
 # @param1	- system name
 # @param2	- pushgateway url
 ##
function pushBackupStartMetrics {
    udt=$(date +%s)
    echo "Pushing start time for system=$1: $udt"
    printf "backup_latest_start_unix_timestamp $udt\n" | curl --data-binary @- $2/metrics/job/backup/system/$( printf %s "$1"|jq -sRr @uri )
}

