#!/usr/bin/env bash
set -e

# Require root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Try: sudo $0" >&2
    exit 1
fi

CONFIG_FILE="config"

# --from-config: ignore any other flags and use the saved config file instead.
# If the config file does not exist, create an empty one and exit.
for arg in "$@"; do
    if [ "$arg" = "--from-config" ]; then
        if [ ! -f "$CONFIG_FILE" ]; then
            : > "$CONFIG_FILE"
            echo "Config file '$CONFIG_FILE' created. Add flags to it, then re-run with --from-config."
            exit 0
        fi
        echo "Using flags from config file '$CONFIG_FILE'."
        eval "set -- $(cat "$CONFIG_FILE")"
        break
    fi
done

# Parse args: optional --cron="..." (5-field schedule) and
# --no-reboot / --no-full-upgrade / --verbose-log / --no-autoremove / --no-autoclean flags
ALLOW_REBOOT=true
UPGRADE_TYPE=full-upgrade
VERBOSE_LOG=0
AUTOREMOVE=true
AUTOCLEAN=true
CRON_SCHEDULE=""
USED_FLAGS=()
for arg in "$@"; do
    case "$arg" in
        --cron=*)
            CRON_SCHEDULE="${arg#--cron=}"
            ;;
        --no-reboot)
            ALLOW_REBOOT=false
            ;;
        --no-full-upgrade)
            UPGRADE_TYPE=upgrade
            ;;
        --verbose-log)
            VERBOSE_LOG=1 ;;
        --no-autoremove)
            AUTOREMOVE=false ;;
        --no-autoclean)
            AUTOCLEAN=false ;;
        *)
            continue
            ;;
    esac
    USED_FLAGS+=("$arg")
done
# Default schedule if --cron is not provided
CRON_SCHEDULE="${CRON_SCHEDULE:-* * * * *}"

if [ "${#USED_FLAGS[@]}" -gt 0 ]; then
    echo "Setting up autoupdate with flags: ${USED_FLAGS[*]}"
else
    echo "Setting up autoupdate with default options (no flags set)."
fi

# install the script
echo "Installing update script to /usr/local/sbin/autoupdate ..."
install -m 0755 src/autoupdate.sh /usr/local/sbin/autoupdate

# setup the cron job — settings are passed inline as environment variables so
# there is no separate config file written to the system
echo "Installing cron job to /etc/cron.d/autoupdate ..."
cat > /etc/cron.d/autoupdate << EOF
# Run system auto-update on schedule: ${CRON_SCHEDULE}
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
${CRON_SCHEDULE} root ALLOW_REBOOT=${ALLOW_REBOOT} UPGRADE_TYPE=${UPGRADE_TYPE} VERBOSE_LOG=${VERBOSE_LOG} AUTOREMOVE=${AUTOREMOVE} AUTOCLEAN=${AUTOCLEAN} /usr/local/sbin/autoupdate.sh
EOF
chmod 0644 /etc/cron.d/autoupdate


# Install logrotate config
echo "Installing logrotate config to /etc/logrotate.d/autoupdate ..."
cat > /etc/logrotate.d/autoupdate <<'EOF'
/var/log/autoupdate.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    copytruncate
}
EOF

echo "Done. autoupdate is set up and will run on schedule: ${CRON_SCHEDULE}"
