FROM python:3.11-alpine

# Set working directory
WORKDIR /app

# Install bash for startup script
RUN apk add --no-cache bash

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY . .

# Make startup scripts executable
RUN chmod +x start.sh stop.sh 2>/dev/null || true

# Expose port
EXPOSE 5000

# Environment variables
ENV APP_TYPE=flask
ENV PORT=5000

# Use startup script or fallback to direct python
CMD ["python", "app.py"]
