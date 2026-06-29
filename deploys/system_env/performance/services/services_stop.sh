#!/usr/bin/env bash
set -euo pipefail

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        echo "Run as root, or install sudo for non-root execution." >&2
        exit 1
    fi
fi

if ! command -v systemctl >/dev/null 2>&1; then
    echo "systemctl not found; nothing to disable."
    exit 0
fi

units=(
    # Mobile broadband / desktop-only service.
    ModemManager.service

    # Error reporting / crash upload.
    apport.service
    apport-autoreport.service
    kerneloops.service
    whoopsie.service

    # Automatic apt update / upgrade jobs.
    apt-daily.service
    apt-daily.timer
    apt-daily-upgrade.service
    apt-daily-upgrade.timer
    unattended-upgrades.service
    update-notifier-download.timer
    update-notifier-motd.timer

    # News / telemetry-like background jobs.
    motd-news.service
    motd-news.timer
    ua-timer.service
    ua-timer.timer
    popularity-contest.timer
)

for unit in "${units[@]}"; do
    $SUDO systemctl stop "$unit" >/dev/null 2>&1 || true
    $SUDO systemctl disable "$unit" >/dev/null 2>&1 || true
    $SUDO systemctl mask "$unit" >/dev/null 2>&1 || true
done
