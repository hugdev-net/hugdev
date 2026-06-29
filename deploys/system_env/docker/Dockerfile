# syntax=docker/dockerfile:1.7

# Build:
#   docker build -f docker/Dockerfile -t ubuntu22_base .

FROM ubuntu:22.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

LABEL org.opencontainers.image.title="ubuntu22_base" \
      org.opencontainers.image.description="Ubuntu 22.04 base image with apt source, performance limits, locale, timezone, and production service baseline."

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    LD_LIBRARY_PATH=/lib64:/usr/lib64:/usr/local/lib64:/lib:/usr/lib:/usr/local/lib

COPY apt/sources.list.ubuntu22.04 /etc/apt/sources.list
COPY performance/etc/security/limits.conf /etc/security/limits.conf
COPY performance/etc/sysctl.conf /etc/sysctl.conf
COPY performance/services/services_stop.sh /usr/local/sbin/services_stop.sh

RUN set -eux; \
    chmod 0755 /usr/local/sbin/services_stop.sh; \
    printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d; \
    chmod 0755 /usr/sbin/policy-rc.d; \
    printf 'APT::Install-Recommends "false";\nAPT::Install-Suggests "false";\n' > /etc/apt/apt.conf.d/10no-recommends; \
    { \
      printf 'APT::Periodic::Enable "0";\n'; \
      printf 'APT::Periodic::Update-Package-Lists "0";\n'; \
      printf 'APT::Periodic::Unattended-Upgrade "0";\n'; \
      printf 'APT::Periodic::AutocleanInterval "0";\n'; \
    } > /etc/apt/apt.conf.d/20auto-upgrades; \
    mkdir -p /etc/systemd/system; \
    for unit in \
      apt-daily.service \
      apt-daily.timer \
      apt-daily-upgrade.service \
      apt-daily-upgrade.timer \
      unattended-upgrades.service \
      update-notifier-download.timer \
      update-notifier-motd.timer \
      motd-news.service \
      motd-news.timer \
      ua-timer.service \
      ua-timer.timer \
      apport.service \
      apport-autoreport.service \
      kerneloops.service \
      whoopsie.service \
      ModemManager.service; \
    do \
      ln -sf /dev/null "/etc/systemd/system/${unit}"; \
    done; \
    mkdir -p /etc/default; \
    printf 'ENABLED=0\n' > /etc/default/motd-news

RUN set -eux; \
    export LANG=C.UTF-8 LC_ALL=C.UTF-8; \
    apt-get update; \
    apt-get purge -y \
      unattended-upgrades \
      update-notifier-common \
      ubuntu-release-upgrader-core \
      popularity-contest \
      apport \
      whoopsie \
      kerneloops \
      modemmanager \
      motd-news-config \
      ubuntu-advantage-tools \
      landscape-common \
      snapd || true; \
    apt-get install -y --no-install-recommends \
      bash-completion \
      ca-certificates \
      curl \
      locales \
      procps \
      tzdata; \
    printf 'en_US.UTF-8 UTF-8\n' > /etc/locale.gen; \
    locale-gen en_US.UTF-8; \
    update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en; \
    ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime; \
    echo "${TZ}" > /etc/timezone; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    LC_CTYPE=en_US.UTF-8 \
    SUPPORTED=en_US.UTF-8:en_US:en

RUN set -eux; \
    { \
      printf 'umask 022\n'; \
      printf 'export TZ="${TZ:-Asia/Shanghai}"\n'; \
      printf 'export LANG="${LANG:-en_US.UTF-8}"\n'; \
      printf 'export LANGUAGE="${LANGUAGE:-en_US:en}"\n'; \
      printf 'export LC_ALL="${LC_ALL:-en_US.UTF-8}"\n'; \
      printf 'export LC_CTYPE="${LC_CTYPE:-en_US.UTF-8}"\n'; \
      printf 'export PATH="$PATH:$HOME/bin:$HOME/sbin:$HOME/usr/bin:$HOME/usr/sbin:$HOME/usr/local/bin:$HOME/usr/local/sbin"\n'; \
      printf 'if [ -d "$HOME/apps" ]; then app_bins="$(find "$HOME/apps" -type d -name bin 2>/dev/null | paste -sd: -)"; [ -n "$app_bins" ] && export PATH="$app_bins:$PATH"; fi\n'; \
    } > /etc/profile.d/00-system-env.sh; \
    chmod 0644 /etc/profile.d/00-system-env.sh

CMD ["/bin/bash"]
