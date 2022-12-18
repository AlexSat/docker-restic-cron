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
        docker stop "${arrayContainers[$i]}" || true
    done
    echo "Dependent containers stopped: $1"
}

## 
 # Use it to start docker containers
 # @param1      - array with container names
 ##
function startDockerContainers {
    echo "Starting deppendent containers: $1"
    local arrayContainers=
    IFS=' ' read -r -a arrayContainers <<< "$1"
    local min=0
    local max=$(( ${#arrayContainers[@]} ))

    for (( i=$min; i<$max; i++ ))
    do
        docker start "${arrayContainers[$i]}" || true
    done
    echo "Dependent containers started: $1"
}