FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo
ENV DISPLAY=:1
ENV RESOLUTION=1920x1080
ENV XDG_RUNTIME_DIR=/tmp/runtime-ubuntu

# --------------------------------------------------
# Ubuntu Desktop completo + GNOME + noVNC
# --------------------------------------------------

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ubuntu-desktop \
        ubuntu-standard \
        gnome-shell \
        gnome-session \
        gnome-terminal \
        gnome-control-center \
        nautilus \
        dbus-x11 \
        x11vnc \
        xvfb \
        novnc \
        websockify \
        sudo \
        curl \
        wget \
        git \
        nano \
        vim \
        htop \
        net-tools \
        iputils-ping \
        ca-certificates \
        software-properties-common \
        mesa-utils \
        x11-utils \
        procps \
        unzip \
        zip \
        firefox \
        libreoffice \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------
# Usuário Ubuntu
# Ubuntu 24.04 normalmente já possui esse usuário.
# --------------------------------------------------

RUN if ! id -u ubuntu >/dev/null 2>&1; then \
        useradd -m -s /bin/bash ubuntu; \
    fi && \
    mkdir -p /home/ubuntu && \
    chown ubuntu:ubuntu /home/ubuntu && \
    usermod -aG sudo ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu

# --------------------------------------------------
# Diretórios necessários
# --------------------------------------------------

RUN mkdir -p \
        /home/ubuntu/.vnc \
        /tmp/runtime-ubuntu \
        /data \
    && chown -R ubuntu:ubuntu \
        /home/ubuntu \
        /tmp/runtime-ubuntu \
        /data \
    && chmod 700 /tmp/runtime-ubuntu

# --------------------------------------------------
# Script de inicialização
# --------------------------------------------------

COPY start.sh /start.sh

RUN chmod +x /start.sh

# Railway encaminhará o domínio público para
# a porta definida em $PORT
EXPOSE 6080

CMD ["/start.sh"]
