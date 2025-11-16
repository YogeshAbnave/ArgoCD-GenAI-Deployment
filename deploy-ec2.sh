#!/bin/bash

###################################
# Flask Weather App - EC2 Deployment Script
# Deploys Flask application to EC2 instance
###################################

set -e

### -------------------------------
### CONFIGURATION
### -------------------------------
GITHUB_REPO="https://github.com/YogeshAbnave/ArgoCD-GenAI-Deployment.git"
BRANCH="main"
APP_DIR="/opt/app"
PYTHON_BIN="python3"
PORT="${PORT:-5000}"
FLASK_APP="app.py"

echo "========================================="
echo "🌤️  Flask Weather App Deployment"
echo "========================================="
echo "Repository: $GITHUB_REPO"
echo "Branch: $BRANCH"
echo "Port: $PORT"
echo "========================================="

### -------------------------------
### STEP 1: SYSTEM UPDATE & DEPENDENCIES
### -------------------------------
echo "📦 Updating system and installing dependencies..."
sudo yum update -y || sudo apt-get update -y
sudo yum install -y git python3 python3-pip gcc python3-devel wget curl || \
sudo apt-get install -y git python3 python3-pip gcc python3-dev wget curl

### -------------------------------
### STEP 2: CREATE APP DIRECTORY
### -------------------------------
echo "📁 Creating application directory..."
sudo mkdir -p $APP_DIR
sudo chown -R $USER:$USER $APP_DIR
cd $APP_DIR

### -------------------------------
### STEP 3: CLONE OR UPDATE REPOSITORY
### -------------------------------
if [ ! -d "$APP_DIR/.git" ]; then
    echo "🧬 Cloning repository..."
    git clone -b $BRANCH $GITHUB_REPO $APP_DIR
else
    echo "🔄 Updating repository..."
    git fetch origin
    git reset --hard origin/$BRANCH
fi

### -------------------------------
### STEP 4: PYTHON VIRTUAL ENVIRONMENT
### -------------------------------
echo "🐍 Setting up Python virtual environment..."
rm -rf venv
$PYTHON_BIN -m venv venv
source venv/bin/activate

echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

### -------------------------------
### STEP 5: STOP OLD PROCESSES
### -------------------------------
echo "🧹 Stopping old Flask processes..."
pkill -f "flask" || true
pkill -f "$FLASK_APP" || true
sleep 2

### -------------------------------
### STEP 6: START FLASK APPLICATION
### -------------------------------
echo "🚀 Starting Flask app on port $PORT..."

if [ ! -f "$FLASK_APP" ]; then
    echo "❌ Error: Flask app not found at $FLASK_APP"
    exit 1
fi

export FLASK_APP="$FLASK_APP"
export FLASK_ENV="production"

nohup venv/bin/python "$FLASK_APP" > flask.log 2>&1 &
APP_PID=$!

sleep 4

if ps -p $APP_PID > /dev/null 2>&1; then
    echo "✅ Flask started successfully (PID: $APP_PID)"
else
    echo "❌ Flask failed to start. Logs:"
    tail -20 flask.log
    exit 1
fi

### -------------------------------
### STEP 7: CONFIGURE FIREWALL
### -------------------------------
echo "🔓 Configuring firewall for port $PORT..."
sudo firewall-cmd --add-port=${PORT}/tcp --permanent 2>/dev/null || true
sudo firewall-cmd --reload 2>/dev/null || true
sudo iptables -I INPUT -p tcp --dport $PORT -j ACCEPT 2>/dev/null || true

### -------------------------------
### STEP 8: INSTALL DOCKER (OPTIONAL)
### -------------------------------
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    sudo apt-get install -y docker.io || sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo "✅ Docker installed successfully"
else
    echo "✅ Docker already installed"
fi

### -------------------------------
### STEP 9: DEPLOYMENT INFO
### -------------------------------
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || echo "Unable to fetch")
PRIVATE_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "========================================="
echo "✅ DEPLOYMENT SUCCESSFUL!"
echo "========================================="
echo "📂 App directory: $APP_DIR"
echo "🆔 Process ID: $APP_PID"
echo ""
echo "🌐 Access URLs:"
echo "   Public:  http://${PUBLIC_IP}:${PORT}"
echo "   Private: http://${PRIVATE_IP}:${PORT}"
echo ""
echo "📜 View logs:"
echo "   tail -f $APP_DIR/flask.log"
echo ""
echo "🛑 Stop app:"
echo "   pkill -f flask"
echo ""
echo "🔄 Redeploy:"
echo "   bash $APP_DIR/deploy-ec2.sh"
echo "========================================="