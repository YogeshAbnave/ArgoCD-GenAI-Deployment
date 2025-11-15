# 🌤️ Flask Weather App - EC2 Deployment Guide

Simple guide to deploy the Flask weather application on AWS EC2.

## 📋 What This App Does

A Flask web application that shows weather information for any city using the OpenWeatherMap API.

## 🚀 Quick Deploy to EC2

### Step 1: Launch EC2 Instance

- **AMI**: Amazon Linux 2
- **Instance Type**: t2.micro (free tier)
- **Security Group**: Allow inbound on port 5000

### Step 2: SSH and Deploy

```bash
# SSH into your EC2
ssh -i your-key.pem ec2-user@your-ec2-ip

# One-command deployment
curl -sSL https://raw.githubusercontent.com/YogeshAbnave/ArgoCD-GenAI-Deployment/main/deploy-ec2.sh | bash
```

### Step 3: Access Your App

```
http://YOUR-EC2-PUBLIC-IP:5000
```

## 🔧 Manual Deployment

If you prefer step-by-step:

```bash
# 1. SSH into EC2
ssh -i your-key.pem ec2-user@your-ec2-ip

# 2. Download deployment script
wget https://raw.githubusercontent.com/YogeshAbnave/ArgoCD-GenAI-Deployment/main/deploy-ec2.sh

# 3. Make it executable
chmod +x deploy-ec2.sh

# 4. Run deployment
bash deploy-ec2.sh
```

## 🎛️ Management Commands

```bash
# Start the app
bash /opt/app/manage.sh start

# Stop the app
bash /opt/app/manage.sh stop

# Restart the app
bash /opt/app/manage.sh restart

# Check status
bash /opt/app/manage.sh status

# View logs
bash /opt/app/manage.sh logs

# Update to latest version
bash /opt/app/manage.sh deploy
```

## 🔒 Security Group Configuration

Make sure your EC2 Security Group allows:

| Type | Protocol | Port | Source |
|------|----------|------|--------|
| HTTP | TCP | 5000 | 0.0.0.0/0 |
| SSH | TCP | 22 | Your IP |

## 📊 Check Application Status

```bash
# Check if Flask is running
ps aux | grep flask

# Check port
netstat -tulpn | grep 5000

# View logs
tail -f /opt/app/flask.log
```

## 🔄 Update Application

```bash
cd /opt/app
git pull origin main
bash /opt/app/stop.sh
bash /opt/app/deploy-ec2.sh
```

## 🐛 Troubleshooting

### App won't start?

```bash
# Check logs
tail -50 /opt/app/flask.log

# Verify Python dependencies
cd /opt/app
source venv/bin/activate
pip list
```

### Port already in use?

```bash
# Find process
sudo lsof -i :5000

# Kill it
sudo kill -9 <PID>

# Or use stop script
bash /opt/app/stop.sh
```

### Can't access from browser?

1. Check Security Group allows port 5000
2. Verify Flask is running: `ps aux | grep flask`
3. Test locally: `curl http://localhost:5000`
4. Check firewall: `sudo firewall-cmd --list-all`

## 📁 File Structure

```
/opt/app/
├── app.py              # Main Flask application
├── requirements.txt    # Python dependencies
├── templates/          # HTML templates
├── static/            # CSS/JS files
├── deploy-ec2.sh      # Deployment script
├── manage.sh          # Management script
├── stop.sh            # Stop script
└── flask.log          # Application logs
```

## 🌐 Environment Variables

Customize deployment:

```bash
# Change port (default: 5000)
export PORT=8080
bash deploy-ec2.sh
```

## 📞 Support

- GitHub: https://github.com/YogeshAbnave/ArgoCD-GenAI-Deployment
- Issues: https://github.com/YogeshAbnave/ArgoCD-GenAI-Deployment/issues
