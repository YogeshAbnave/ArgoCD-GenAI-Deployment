#!/bin/bash

set -e

###################################
# Flask Weather App Deployment Script (Ubuntu Version)
###################################

GITHUB_USER="YogeshAbnave"
GITHUB_REPO="https://github.com/YogeshAbnave/ArgoCD-GenAI-Deployment.git"
BRANCH="main"
APP_DIR="/opt/app"
PYTHON_BIN="python3"
PORT="${PORT:-5000}"
FLASK_APP="app.py"

echo "========================================="
echo "🌤️  Flask Weather App Deployment (Ubuntu)"
echo "========================================="
echo "Repository: $GITHUB_REPO"
echo "Branch: $BRANCH"
echo "Port: $PORT"
echo "========================================="

### STEP 1: Update & Install Dependencies
echo "📦 Updating packages..."
sudo apt-get update -y
sudo apt-get install -y git python3 python3-pip python3-venv gcc

### STEP 2: Create App Directory
echo "📁 Creating app directory..."
sudo mkdir -p $APP_DIR
sudo chown -R ubuntu:ubuntu $APP_DIR
cd $APP_DIR

### STEP 3: Clone or Pull Repository
if [ ! -d "$APP_DIR/.git" ]; then
    echo "🧬 Cloning repository..."
    git clone -b $BRANCH $GITHUB_REPO $APP_DIR
else
    echo "🔄 Pulling latest changes..."
    git fetch origin
    git reset --hard origin/$BRANCH
fi

### STEP 4: Setup Virtual Environment
echo "🐍 Creating virtual environment..."
[ -d venv ] && rm -rf venv

$PYTHON_BIN -m venv venv
source venv/bin/activate

echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

### STEP 5: Kill Old Processes
echo "🧹 Removing old processes..."
pkill -f "flask" || true
pkill -f "$FLASK_APP" || true

### STEP 6: Run Flask App
echo "🚀 Starting Flask on port $PORT..."
export FLASK_APP="$FLASK_APP"
export FLASK_ENV=production

nohup venv/bin/python "$FLASK_APP" > flask.log 2>&1 &
APP_PID=$!

sleep 5

if ps -p $APP_PID > /dev/null; then
    echo "✅ Flask running with PID $APP_PID"
else
    echo "❌ Flask failed to start!"
    tail -20 flask.log
    exit 1
fi

### STEP 7: Open Firewall Port
echo "🔓 Allowing port $PORT through UFW..."
sudo ufw allow $PORT || true

### STEP 8: Show Info
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)
PRIVATE_IP=$(hostname -I | awk '{print $1}')

echo "========================================="
echo "🎉 Deployment Complete!"
echo "Public URL:  http://$PUBLIC_IP:$PORT"
echo "Private URL: http://$PRIVATE_IP:$PORT"
echo "Logs: tail -f $APP_DIR/flask.log"
echo "========================================="






sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker
docker --version
