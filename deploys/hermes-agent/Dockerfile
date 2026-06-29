# syntax=docker/dockerfile:1.7

# Build:
#   socat TCP-LISTEN:7898,bind=172.17.0.1,fork,reuseaddr TCP:127.0.0.1:7898
#   docker build --add-host=host.docker.internal=host-gateway --progress=plain -t hermes_agent_base .
#   docker run --rm -it hermes_agent_base bash

FROM ubuntu22_base:latest

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG USER=agent
ARG GROUP=${USER}
ARG USER_ID=1263
ARG GROUP_ID=${USER_ID}
ARG HERMES_INSTALL_URL=https://hermes-agent.nousresearch.com/install.sh
ARG PROXY_URL=socks5://host.docker.internal:7898/

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/${USER} \
    TZ=Asia/Shanghai \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HERMES_HOME=/home/${USER}/.hermes \
    HERMES_WRITE_SAFE_ROOT=/workspace \
    HERMES_DISABLE_LAZY_INSTALLS=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH=/home/${USER}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN set -eux; \
    apt-get update; \
    apt-get purge -y unattended-upgrades update-notifier-common ubuntu-release-upgrader-core motd-news-config || true; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      vim \
      xz-utils \
      net-tools \
      iputils-ping \
      tini \
      ripgrep \
      ffmpeg \
      libffi-dev \
      libssl-dev; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN set -eux; \
    groupadd --gid "${GROUP_ID}" ${USER}; \
    useradd --uid "${USER_ID}" --gid "${GROUP_ID}" --create-home --home-dir /home/${USER} --shell /bin/bash ${USER}; \
    install -d -o ${USER} -g ${GROUP} -m 0750 /home/${USER}/.hermes; \
    install -d -o ${USER} -g ${GROUP} -m 0755 /workspace

# Install Hermes as the unprivileged user so the checkout, venv, and command
# link are created under the user's home directory.
USER ${USER}

RUN set -eux; \
    cd /home/${USER}; \
    export http_proxy="${PROXY_URL}"; \
    export https_proxy="${PROXY_URL}"; \
    git config --global http.proxy "${PROXY_URL}"; \
    git config --global https.proxy "${PROXY_URL}"; \
    curl -fsSL "${HERMES_INSTALL_URL}" | bash -s -- --no-skills --skip-browser --skip-setup --non-interactive

WORKDIR /workspace

EXPOSE 26707
VOLUME ["/home/${USER}/.hermes", "/workspace"]

ENTRYPOINT ["/usr/bin/tini", "--", "hermes"]
CMD []
