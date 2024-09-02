# Use an official Python runtime as a parent image
FROM 10.0.0.22:8082/python:3.12.5-bullseye

# Set the working directory in the container
WORKDIR /app
RUN mkdir -p /etc/pip && \
    echo "[global]" > /etc/pip/pip.conf && \
    echo "index = http://10.0.0.22:8081/repository/python-pypi-proxy/pypi" >> /etc/pip/pip.conf && \
    echo "index-url = http://10.0.0.22:8081/repository/python-pypi-proxy/simple" >> /etc/pip/pip.conf && \
    echo "trusted-host = 10.0.0.22:8081" >> /etc/pip/pip.conf

# Install system dependencies if needed, 
# not supported by Nexus unfortunately
RUN apt-get update -y
RUN apt upgrade -y

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the current directory contents into the container
COPY . .

# Expose port 80 to the outside world
EXPOSE 80

# Run app.py when the container launches
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
