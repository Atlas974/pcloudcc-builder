#!/usr/bin/env bash

set -euo pipefail

# Upload to pCloud
# Current version of pcloudcc doesn't support command to check if threre are pending transfers. 
# Locally cached files are located under ~/.pcloud/Cache dir. 
# When there is only one file ~/.pcloud/Cache/cached (ususally big sized) this mean that transfers are completed.

PCLOUD_ROOT_DIR="/media/pcloud"
PCLOUD_CACHE_DIR="/root/.pcloud/Cache"

SOURCE_DIR="${1:-}"
RSYNC_ADDITIONAL_OPTIONS="${2:-}"

# check that source dir is provided
if [ -z "$SOURCE_DIR" ]; then
    echo "Please provide source dir" >&2
    exit 1
fi

# check that source dir is executable
if [ ! -x "$SOURCE_DIR" ]; then
    echo "Source dir $SOURCE_DIR is not executable" >&2
    exit 1
fi

# check that target dir is writable
if [ ! -w "$PCLOUD_ROOT_DIR" ]; then
    echo "Target dir $PCLOUD_ROOT_DIR is not writable" >&2
    exit 1
fi

# check that pcloud is mounted
if ! mount | grep -q "$PCLOUD_ROOT_DIR"; then
    echo "pCloud is not mounted" >&2
    exit 1
fi

# check that pcloud service is running
if ! systemctl is-active --quiet pcloudcc.service; then
    echo "pCloud service is not running" >&2
    exit 1
fi

# check that no rsync with same target dir is running
if pgrep -f "rsync.*$PCLOUD_ROOT_DIR" >/dev/null; then
    echo "rsync with target dir $PCLOUD_ROOT_DIR is already running" >&2
    exit 1
fi

# upload files using rsync
# -a is archive mode (recursive copy + retain attributes)
# -v is verbose
# -h is human readable
# -W is copy whole files (without delta-xfer algorithm to reduce CPU usage)
# -P is --partial --progress (keep partially transferred files + show progress during transfer)

# Function to watch root disk usage and kill a process by PID
monitor_disk_usage() {
    local pid="$1"
    local process_name="$(ps -p $pid -o comm=)"
    local max_disk_usage="${2:-50}"

    echo "Started monitoring root disk usage for process: $process_name (PID: $pid)" >&2
    echo "Process $process_name (PID: $pid) will be killed if root disk usage exceeds ${max_disk_usage}%" >&2

    while kill -0 $pid 2>/dev/null; do
        ROOT_DISK_USAGE=$(df -h | awk '/\/$/ {print $5}' | sed 's/%//')
        if [ "$ROOT_DISK_USAGE" -gt 50 ]; then
            echo "Root disk usage is at ${ROOT_DISK_USAGE}%: killing process $process_name (PID: $pid)" >&2
            kill $pid
            break
        fi
        sleep 10
    done

    echo "Stopped monitoring root disk usage for process: $process_name (PID: $pid)" >&2
}

UPLOAD_COMPLETED=false

while ! $UPLOAD_COMPLETED; do
    # wait until there are no pending transfers
    until [ "$(ls -A $PCLOUD_CACHE_DIR 2>/dev/null | wc -l)" -eq 1 ]; do
        echo "There are pending transfers. Waiting 10 seconds..." >&2
        sleep 10
    done

    # run rsync in background and get its pid
    rsync -avhWP $RSYNC_ADDITIONAL_OPTIONS "$SOURCE_DIR" "$PCLOUD_ROOT_DIR" &
    RSYNC_PID=$!

    # Start monitoring disk usage and killing rsync if necessary
    monitor_disk_usage $RSYNC_PID &

    # Wait for rsync to finish and get its exit status
    if wait $RSYNC_PID; then
        UPLOAD_COMPLETED=true
    else
        UPLOAD_COMPLETED=false
    fi
done
