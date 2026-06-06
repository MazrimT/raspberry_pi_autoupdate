#!/usr/bin/env bash
set -e

LOGFILE="/var/log/autoupdate.log"

# Settings (e.g. ALLOW_REBOOT=false, UPGRADE_TYPE=upgrade, VERBOSE_LOG=1) are passed
# in as environment variables by the cron job; fall back to defaults otherwise.
ALLOW_REBOOT="${ALLOW_REBOOT:-true}"
UPGRADE_TYPE="${UPGRADE_TYPE:-full-upgrade}"
VERBOSE_LOG="${VERBOSE_LOG:-0}"
AUTOREMOVE="${AUTOREMOVE:-true}"
AUTOCLEAN="${AUTOCLEAN:-true}"

# When verbose, raw command output goes to the log file; otherwise it is discarded
if [ "$VERBOSE_LOG" = "1" ]; then
    CMD_OUTPUT="$LOGFILE"
else
    CMD_OUTPUT=/dev/null
fi

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOGFILE"
}

log "==== Starting update ===="

#Update package lists
apt update >> "$CMD_OUTPUT" 2>&1

# Upgrade all packages
DEBIAN_FRONTEND=noninteractive apt -y "$UPGRADE_TYPE" >> "$CMD_OUTPUT" 2>&1

# Remove unused packages
if [ "$AUTOREMOVE" = "true" ]; then
    apt -y autoremove >> "$CMD_OUTPUT" 2>&1
fi
if [ "$AUTOCLEAN" = "true" ]; then
    apt -y autoclean >> "$CMD_OUTPUT" 2>&1
fi

# Reboot if needed
if [ -f /var/run/reboot-required ]; then
    if [ "$ALLOW_REBOOT" = "true" ]; then
        log "Reboot required — rebooting"
        reboot
    else
        log "Reboot required but reboots are disabled, update complete."
    fi
else
    log "No reboot required, update complete."
fi
