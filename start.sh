#!/bin/bash

set -e

export DISPLAY=:1
export RESOLUTION="${RESOLUTION:-1920x1080}"
export PORT="${PORT:-6080}"
export XDG_RUNTIME_DIR=/tmp/runtime-ubuntu

echo ""
echo "============================================"
echo "       UBUNTU CLOUD DESKTOP"
echo "============================================"
echo ""

echo "PORT: $PORT"
echo "DISPLAY: $DISPLAY"
echo "RESOLUTION: $RESOLUTION"

echo ""
echo "------------- CPU --------------------------"
nproc || true

echo ""
echo "------------- RAM --------------------------"
free -h || true

echo ""
echo "------------- DISCO ------------------------"
df -h || true

echo ""
echo "------------- GPU --------------------------"
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi || true
else
    echo "nvidia-smi não encontrado."
fi

echo ""
echo "============================================"

# --------------------------------------------------
# Preparação
# --------------------------------------------------

mkdir -p /home/ubuntu/.vnc
mkdir -p "$XDG_RUNTIME_DIR"

chown -R ubuntu:ubuntu /home/ubuntu
chown ubuntu:ubuntu "$XDG_RUNTIME_DIR"

chmod 700 "$XDG_RUNTIME_DIR"

# --------------------------------------------------
# Senha VNC
# --------------------------------------------------

if [ -z "${VNC_PASSWORD:-}" ]; then
    echo ""
    echo "ATENÇÃO: VNC_PASSWORD não foi definida."
    echo "Utilizando senha temporária padrão."
    VNC_PASSWORD="ubuntu123"
fi

x11vnc \
    -storepasswd "$VNC_PASSWORD" \
    /home/ubuntu/.vnc/passwd

chown ubuntu:ubuntu /home/ubuntu/.vnc/passwd
chmod 600 /home/ubuntu/.vnc/passwd

# --------------------------------------------------
# Limpeza de sessão anterior
# --------------------------------------------------

rm -f /tmp/.X1-lock
rm -f /tmp/.X11-unix/X1

mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# --------------------------------------------------
# X SERVER
# --------------------------------------------------

echo ""
echo "[1/4] Iniciando servidor gráfico..."

Xvfb :1 \
    -screen 0 "${RESOLUTION}x24" \
    -ac \
    +extension GLX \
    +render \
    -noreset &

XVFB_PID=$!

sleep 4

if ! kill -0 "$XVFB_PID" 2>/dev/null; then
    echo "ERRO: Xvfb não iniciou."
    exit 1
fi

echo "Xvfb iniciado."

# --------------------------------------------------
# GNOME
# --------------------------------------------------

echo ""
echo "[2/4] Iniciando Ubuntu Desktop..."

su - ubuntu -c "
    export DISPLAY=:1
    export XDG_RUNTIME_DIR=/tmp/runtime-ubuntu
    export DBUS_SESSION_BUS_ADDRESS=
    dbus-launch --exit-with-session gnome-session
" &

sleep 10

# --------------------------------------------------
# VNC
# --------------------------------------------------

echo ""
echo "[3/4] Iniciando x11vnc..."

x11vnc \
    -display :1 \
    -forever \
    -shared \
    -rfbport 5900 \
    -rfbauth /home/ubuntu/.vnc/passwd \
    -noxdamage \
    -repeat \
    -xkb &

VNC_PID=$!

sleep 3

if ! kill -0 "$VNC_PID" 2>/dev/null; then
    echo "ERRO: x11vnc não iniciou."
    exit 1
fi

echo "VNC iniciado na porta 5900."

# --------------------------------------------------
# noVNC / Railway
# --------------------------------------------------

echo ""
echo "[4/4] Iniciando noVNC..."

echo ""
echo "============================================"
echo " UBUNTU DESKTOP PRONTO"
echo ""
echo " noVNC PORT: $PORT"
echo " Railway Domain -> $PORT"
echo "============================================"
echo ""

exec websockify \
    --web=/usr/share/novnc \
    "0.0.0.0:${PORT}" \
    localhost:5900
