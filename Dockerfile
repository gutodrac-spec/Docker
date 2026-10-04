FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo
ENV DISPLAY=:1
ENV RESOLUTION=1920x1080

RUN apt-get update && apt-get install -y \
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
    htop \
    net-tools \
    ca-certificates \
    software-properties-common \
    mesa-utils \
    firefox \
    libreoffice \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash ubuntu && \
    usermod -aG sudo ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 6080

CMD ["/start.sh"]
