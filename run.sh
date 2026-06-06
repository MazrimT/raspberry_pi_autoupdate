#!/usr/bin/env bash
set -e

# Always operate from the repo root (where this script lives) so the
# relative paths inside src/setup.sh and the config file resolve correctly.
cd "$(dirname "${BASH_SOURCE[0]}")"

CONFIG_FILE="config"

usage() {
    cat <<'EOF'
raspberry_pi_autoupdate — run.sh commands
=========================================

Usage:  sudo ./run.sh <command> [options]

  setup                  Install the autoupdate script + cron job, then save the
                         chosen options to the config file.
    --cron="* * * * *"   cron schedule (5 fields)   [default: * * * * *]
    --no-reboot          never reboot, even if a reboot is required
    --always-reboot      always reboot after every run, even if not required
    --no-full-upgrade    use "apt upgrade" instead of "apt full-upgrade"
    --no-autoremove      skip "apt autoremove"
    --no-autoclean       skip "apt autoclean"
    --verbose-log        log full apt output, not just summaries
    --no-config          do not create/touch the config file
    --from-config        re-run setup using the options saved in the config file

  teardown               Remove everything setup installed (logs kept by default).
    --delete-logs        also delete /var/log/autoupdate.log*

  help                   Show this help.

Most commands need root: prefix them with sudo.
EOF
}

cmd="${1:-help}"
[ "$#" -gt 0 ] && shift || true

case "$cmd" in
    setup)
        bash src/setup.sh "$@"

        # Save the passed options so they can be replayed with 'setup --from-config'
        # (skipped when --no-config or --from-config is passed)
        skip_config=0
        for a in "$@"; do
            if [ "$a" = "--no-config" ] || [ "$a" = "--from-config" ]; then skip_config=1; fi
        done
        if [ "$skip_config" = "1" ]; then
            echo "Leaving config file untouched."
        else
            # If a config file already exists, confirm before overwriting it
            write_config=1
            if [ -f "$CONFIG_FILE" ]; then
                read -r -p "Config file '$CONFIG_FILE' already exists. Overwrite it? [y/N] " answer
                case "$answer" in
                    [Yy]|[Yy][Ee][Ss]) ;;
                    *) write_config=0 ;;
                esac
            fi

            if [ "$write_config" = "0" ]; then
                echo "Keeping existing config file."
            else
                # Re-quote args that contain spaces so the cron value survives a replay
                quoted=""
                for a in "$@"; do
                    case "$a" in
                        *" "*) quoted="$quoted '$a'" ;;
                        *)     quoted="$quoted $a" ;;
                    esac
                done
                quoted="${quoted# }"
                printf '%s\n' "$quoted" > "$CONFIG_FILE"
            fi
        fi
        ;;

    teardown)
        bash src/teardown.sh "$@"
        ;;

    help|-h|--help)
        usage
        ;;

    *)
        echo "Unknown command: $cmd" >&2
        echo >&2
        usage >&2
        exit 1
        ;;
esac
