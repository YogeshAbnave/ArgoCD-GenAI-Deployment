FROM python:3.11-alpine

# Set working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# Copy rest of the project
COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
