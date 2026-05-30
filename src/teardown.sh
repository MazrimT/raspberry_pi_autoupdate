#!/usr/bin/env bash
set -e

# Require root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Try: sudo $0" >&2
    exit 1
fi

# Parse args: optional --delete-logs flag
DELETE_LOGS=false
for arg in "$@"; do
    case "$arg" in
        --delete-logs) DELETE_LOGS=true ;;
    esac
done

# Remove the installed script
# (remove both names to cover the install-path/cron-path mismatch in setup.sh)
rm -f /usr/local/sbin/autoupdate
rm -f /usr/local/sbin/autoupdate.sh

# Remove the cron job
rm -f /etc/cron.d/autoupdate

# Remove the logrotate config
rm -f /etc/logrotate.d/autoupdate

# Remove the autoupdate config
rm -f /etc/default/autoupdate

# Remove or keep logs depending on the --delete-logs flag
if [ "$DELETE_LOGS" = "true" ]; then
    rm -f /var/log/autoupdate.log*
    echo "autoupdate removed (logs deleted)."
else
    # Logs are intentionally left in place (/var/log/autoupdate.log*)
    echo "autoupdate removed (logs kept in /var/log/autoupdate.log*)."
fi
