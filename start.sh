#!/bin/bash

set -e

export DISPLAY=:1
export PORT="${PORT:-6080}"
export RESOLUTION="${RESOLUTION:-1920x1080}"
export XDG_RUNTIME_DIR=/tmp/runtime-ubuntu

echo "========================================"
echo " UBUNTU CLOUD DESKTOP"
echo "========================================"
echo "RAM disponível:"
free -h

echo ""
echo "CPU:"
nproc

echo ""
echo "GPU:"
nvidia-smi || echo "GPU NVIDIA não detectada"

echo ""
echo "Porta: $PORT"
echo "Resolução: $RESOLUTION"
echo "========================================"

mkdir -p "$XDG_RUNTIME_DIR"
chown ubuntu:ubuntu "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

mkdir -p /home/ubuntu/.vnc
chown -R ubuntu:ubuntu /home/ubuntu

# Senha VNC vinda das Variables da Railway
VNC_PASSWORD="${VNC_PASSWORD:-ubuntu}"

x11vnc -storepasswd \
    "$VNC_PASSWORD" \
    /home/ubuntu/.vnc/passwd

chown ubuntu:ubuntu /home/ubuntu/.vnc/passwd
chmod 600 /home/ubuntu/.vnc/passwd

rm -f /tmp/.X1-lock
rm -rf /tmp/.X11-unix/X1

echo "Iniciando servidor gráfico..."

Xvfb :1 \
    -screen 0 "${RESOLUTION}x24" \
    -ac \
    +extension GLX \
    +render \
    -noreset &

sleep 3

echo "Iniciando Ubuntu Desktop..."

su - ubuntu -c "
export DISPLAY=:1
export XDG_RUNTIME_DIR=/tmp/runtime-ubuntu
dbus-launch --exit-with-session gnome-session
" &

sleep 10

echo "Iniciando VNC..."

x11vnc \
    -display :1 \
    -forever \
    -shared \
    -rfbport 5900 \
    -rfbauth /home/ubuntu/.vnc/passwd \
    -noxdamage &

sleep 2

echo "Iniciando noVNC..."

exec websockify \
    --web=/usr/share/novnc \
    "0.0.0.0:${PORT}" \
    localhost:5900
