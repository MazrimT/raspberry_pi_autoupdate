# autoupdate for raspberry pi
This repo contains some simple tools to set up auto-update and auto-reboot on a raspberry pi.
These are simple shell scripts so should technically work on any ubuntu based system, but only tested on raspberry pi.

# Usage

Everything is driven by `run.sh` in the repo root — no extra tools required, just bash.
Pass options directly after the command.
```SHELL
sudo ./run.sh <command> [options]

# examples:
sudo ./run.sh                                      # show the help/overview
sudo ./run.sh setup                                # install with defaults
sudo ./run.sh setup --cron="30 3 * * *" --no-reboot
sudo ./run.sh setup-from-config                    # replay options saved in the config file
sudo ./run.sh teardown --delete-logs
```

> [!IMPORTANT]
> There is no validation of the input of the cron expression.
> Please check crontab.guru or similar tool. If the expression is not correct it will still be setup up but not work.

- `setup` - installs and sets up the autoupdate.sh script in cron.
  - optional parameters:
    - --cron=""        # defaults to "* * * * *" meaning midnight
    - --no-reboot      # if set does not allow the update script to reboot the device
    - --no-full-upgrade # if set switches "apt full-upgrade" to just "apt upgrade"
    - --no-autoremove  # if set skips "apt autoremove" (runs by default)
    - --no-autoclean   # if set skips "apt autoclean" (runs by default)
    - --no-config      # if set the config file is not created or touched
    - --verbose-log    # if set logs full apt output, not just summaries
    - --from-config    # ignores other flags set and uses the config file instead. if no config file creates it but does not add anything to it

- `teardown` - removes everything set up in setup
  - optional parameters:
    - --delete-logs

## config file
run.sh will create a config file, it's just a simple text file `config` in root of the repo with all the flags to run setup with on a single line.

example:
`--cron="0 3 * * *" --verbose-log --always-reboot`
