#!/bin/bash

###################################
# Flask Weather App Deployment Script
# Deploys Flask weather application to EC2
###################################

set -e  # Exit on error

### -------------------------------
### CONFIGURATION
### -------------------------------
GITHUB_USER="YogeshAbnave"
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
echo "📦 Updating system packages..."
sudo yum update -y

echo "📦 Installing Git, Python3, and pip..."
sudo yum install -y git python3 python3-pip

echo "📦 Installing additional dependencies..."
sudo yum install -y gcc python3-devel

### -------------------------------
### STEP 2: CREATE DEPLOYMENT DIRECTORY
### -------------------------------
echo "📁 Creating application directory..."
sudo mkdir -p $APP_DIR
sudo chown -R ec2-user:ec2-user $APP_DIR
cd $APP_DIR

### -------------------------------
### STEP 3: CLONE OR UPDATE REPOSITORY
### -------------------------------
if [ ! -d "$APP_DIR/.git" ]; then
    echo "🧬 Cloning repository..."
    git clone -b $BRANCH $GITHUB_REPO $APP_DIR
else
    echo "🔄 Pulling latest changes..."
    cd $APP_DIR
    git fetch origin
    git reset --hard origin/$BRANCH
fi

### -------------------------------
### STEP 4: PYTHON VIRTUAL ENVIRONMENT
### -------------------------------
echo "🐍 Setting up Python virtual environment..."

# Remove old venv if exists
if [ -d "venv" ]; then
    echo "🧹 Removing old virtual environment..."
    rm -rf venv
fi

$PYTHON_BIN -m venv venv
source venv/bin/activate

echo "📦 Installing Python dependencies..."
pip install --upgrade pip
pip install --ignore-installed -r requirements.txt

### -------------------------------
### STEP 5: CLEANUP OLD PROCESSES
### -------------------------------
echo "🧹 Cleaning up old Flask processes..."
pkill -f "flask" || true
pkill -f "$FLASK_APP" || true
echo "✅ Killed existing Flask processes"
sleep 2

### -------------------------------
### STEP 6: START FLASK APPLICATION
### -------------------------------
echo "🚀 Starting Flask weather app on port $PORT..."

# Check if Flask app exists
if [ ! -f "$FLASK_APP" ]; then
    echo "❌ Error: Flask app not found at $FLASK_APP"
    exit 1
fi

# Set Flask environment variables
export FLASK_APP="$FLASK_APP"
export FLASK_ENV=production

# Start Flask app
nohup venv/bin/python "$FLASK_APP" > flask.log 2>&1 &

APP_PID=$!
echo "✅ Flask started with PID: $APP_PID"
echo "📝 Logs: tail -f $APP_DIR/flask.log"

### -------------------------------
### STEP 7: FIREWALL & SECURITY
### -------------------------------
echo "🔓 Configuring firewall for port $PORT..."
sudo firewall-cmd --add-port=${PORT}/tcp --permanent 2>/dev/null || true
sudo firewall-cmd --reload 2>/dev/null || true

# Alternative: iptables (if firewalld not available)
sudo iptables -I INPUT -p tcp --dport $PORT -j ACCEPT 2>/dev/null || true

### -------------------------------
### STEP 8: VERIFY STARTUP
### -------------------------------
echo "⏳ Waiting for Flask to start..."
sleep 5

if ps -p $APP_PID > /dev/null 2>&1; then
    echo "✅ Flask is running!"
else
    echo "❌ Flask failed to start. Checking logs..."
    tail -30 flask.log
    exit 1
fi

### -------------------------------
### STEP 9: STATUS & ACCESS INFO
### -------------------------------
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || echo "Unable to fetch")
PRIVATE_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "========================================="
echo "✅ Deployment completed successfully!"
echo "========================================="
echo "📂 App directory: $APP_DIR"
echo "🌤️  App: Flask Weather Application"
echo "🆔 Process ID: $APP_PID"
echo ""
echo "🌐 Access URLs:"
echo "   Public:  http://${PUBLIC_IP}:${PORT}"
echo "   Private: http://${PRIVATE_IP}:${PORT}"
echo ""
echo "📜 View logs:"
echo "   tail -f $APP_DIR/flask.log"
echo ""
echo "🛑 Stop application:"
echo "   pkill -f flask"
echo ""
echo "🔄 Redeploy:"
echo "   bash $APP_DIR/deploy-ec2.sh"
echo "========================================="

# Save deployment info
cat > $APP_DIR/deployment-info.txt <<EOF
Deployment Date: $(date)
App: Flask Weather Application
Port: $PORT
PID: $APP_PID
Public IP: $PUBLIC_IP
Private IP: $PRIVATE_IP
Repository: $GITHUB_REPO
Branch: $BRANCH
EOF

echo "💾 Deployment info saved to: $APP_DIR/deployment-info.txt"
