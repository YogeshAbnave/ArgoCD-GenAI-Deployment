#!/bin/bash

###################################
# Flask Weather App Management
###################################

APP_DIR="/opt/app"

show_usage() {
    echo "Usage: $0 {start|stop|restart|status|logs|deploy}"
    echo ""
    echo "Commands:"
    echo "  start   - Start Flask weather app"
    echo "  stop    - Stop Flask weather app"
    echo "  restart - Restart Flask weather app"
    echo "  status  - Show application status"
    echo "  logs    - Show application logs"
    echo "  deploy  - Pull latest code and restart"
    exit 1
}

start_app() {
    echo "🚀 Starting Flask weather app..."
    cd $APP_DIR
    bash deploy-ec2.sh
}

stop_app() {
    echo "🛑 Stopping Flask weather app..."
    pkill -f "flask" || true
    pkill -f "app.py" || true
    echo "✅ Application stopped"
}

restart_app() {
    echo "🔄 Restarting Flask weather app..."
    stop_app
    sleep 2
    start_app
}

show_status() {
    echo "📊 Flask Weather App Status"
    echo "============================"
    
    if pgrep -f "flask\|app.py" > /dev/null; then
        echo "✅ Flask is running"
        echo "PID: $(pgrep -f 'flask\|app.py')"
        echo "Port: 5000"
    else
        echo "❌ Flask is not running"
    fi
    
    if [ -f "$APP_DIR/deployment-info.txt" ]; then
        echo ""
        echo "📋 Deployment Info:"
        cat $APP_DIR/deployment-info.txt
    fi
}

show_logs() {
    echo "📜 Flask Application Logs"
    echo "========================="
    
    if [ -f "$APP_DIR/flask.log" ]; then
        tail -50 $APP_DIR/flask.log
    else
        echo "❌ No logs found at $APP_DIR/flask.log"
    fi
}

deploy_latest() {
    echo "🔄 Deploying latest version..."
    cd $APP_DIR
    git pull origin main
    stop_app
    sleep 2
    start_app
}

# Main script
case "$1" in
    start)
        start_app
        ;;
    stop)
        stop_app
        ;;
    restart)
        restart_app
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    deploy)
        deploy_latest
        ;;
    *)
        show_usage
        ;;
esac
