#!/bin/bash

###################################
# Stop Flask Weather App
###################################

echo "🛑 Stopping Flask weather app..."

# Stop Flask
pkill -f "flask" && echo "✅ Stopped Flask" || echo "ℹ️  No Flask process found"
pkill -f "app.py" && echo "✅ Stopped app.py" || echo "ℹ️  No app.py process found"

echo "✅ Application stopped!"
