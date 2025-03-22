#!/bin/bash

# Improved n8n Installation with Docker, Traefik, and PostgreSQL
# -------------------------------------------------------------

echo "Starting installation process..."

# Check for any updates
echo "Checking for system updates..."
sudo apt update

# Install required tools
echo "Installing curl, wget, and git..."
sudo apt install -y curl wget git

# Install Docker
echo "Installing Docker..."
sudo apt install -y docker.io
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
sudo apt-get update
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.30.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker Compose installation
echo "Verifying Docker Compose installation..."
docker_compose_version=$(sudo docker-compose --version)
echo "Installed: $docker_compose_version"

# Create project directory
echo "Creating project directory..."
mkdir -p ~/n8n-traefik
cd ~/n8n-traefik

# Download docker-compose-postgres.yaml from GitHub
echo "Downloading docker-compose-postgres.yaml from GitHub..."
wget https://raw.githubusercontent.com/dennisrongo/n8n-scripts/refs/heads/master/docker-compose-postgres.yaml -O docker-compose-postgres.yaml

# Fallback to create the local docker-compose-postgres.yaml file if download fails
if [ $? -ne 0 ]; then
    echo "Failed to download docker-compose-postgres.yaml from GitHub. Creating local file instead..."
    cat > docker-compose-postgres.yaml << 'EOL'
version: "3.8"
services:
  traefik:
    image: "traefik"
    restart: always
    command:
      - "--api=true"
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.mytlschallenge.acme.tlschallenge=true"
      - "--certificatesresolvers.mytlschallenge.acme.email=${SSL_EMAIL}"
      - "--certificatesresolvers.mytlschallenge.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - traefik_data:/letsencrypt
      - /var/run/docker.sock:/var/run/docker.sock:ro

  postgres:
    image: postgres:latest
    restart: always
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data

  n8n:
    image: docker.n8n.io/n8nio/n8n
    restart: always
    ports:
      - "127.0.0.1:5678:5678"
    labels:
      - traefik.enable=true
      - traefik.http.routers.n8n.rule=Host(`${SUBDOMAIN}.${DOMAIN_NAME}`)
      - traefik.http.routers.n8n.tls=true
      - traefik.http.routers.n8n.entrypoints=web,websecure
      - traefik.http.routers.n8n.tls.certresolver=mytlschallenge
      - traefik.http.middlewares.n8n.headers.SSLRedirect=true
      - traefik.http.middlewares.n8n.headers.STSSeconds=315360000
      - traefik.http.middlewares.n8n.headers.browserXSSFilter=true
      - traefik.http.middlewares.n8n.headers.contentTypeNosniff=true
      - traefik.http.middlewares.n8n.headers.forceSTSHeader=true
      - traefik.http.middlewares.n8n.headers.SSLHost=${DOMAIN_NAME}
      - traefik.http.middlewares.n8n.headers.STSIncludeSubdomains=true
      - traefik.http.middlewares.n8n.headers.STSPreload=true
      - traefik.http.routers.n8n.middlewares=n8n@docker
    environment:
      - N8N_HOST=${SUBDOMAIN}.${DOMAIN_NAME}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://${SUBDOMAIN}.${DOMAIN_NAME}/
      - GENERIC_TIMEZONE=${GENERIC_TIMEZONE}
      # PostgreSQL configuration
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - DB_POSTGRESDB_SCHEMA=public
      - DB_POSTGRESDB_SSL=false  # Local PostgreSQL typically does not use SSL
    volumes:
      - n8n_data:/home/node/.n8n
volumes:
  traefik_data:
    external: true
  n8n_data:
    external: true
  postgres_data:
EOL
    echo "Local docker-compose-postgres.yaml file created."
fi

# Create .env file
echo "Creating .env file..."
cat > .env << 'EOL'
POSTGRES_USER=n8n
POSTGRES_PASSWORD=n8n_password
POSTGRES_DB=n8n
POSTGRES_NON_ROOT_USER=n8n_user
POSTGRES_NON_ROOT_PASSWORD=n8n_user_password

# The top level domain to serve from
DOMAIN_NAME=example.com

# The subdomain to serve from
SUBDOMAIN=n8n

# DOMAIN_NAME and SUBDOMAIN combined decide where n8n will be reachable from
# above example would result in: <https://n8n.example.com>

# Optional timezone to set which gets used by Cron-Node by default
# If not set New York time will be used
GENERIC_TIMEZONE=America/Los_Angeles

# The email address to use for the SSL certificate creation
SSL_EMAIL=your-email@example.com
EOL

# Setup volumes
echo "Setting up Docker volumes..."
sudo docker volume create traefik_data
sudo docker volume create n8n_data
sudo docker volume create postgres_data

echo "============================================================"
echo "Installation complete! Follow these steps to start n8n:"
echo "1. Edit your .env file with your domain information:"
echo "   nano ~/n8n-traefik/.env"
echo ""
echo "2. Start the containers in detached mode:"
echo "   cd ~/n8n-traefik && sudo docker-compose -f docker-compose-postgres.yaml up -d"
echo ""
echo "3. To view logs:"
echo "   cd ~/n8n-traefik && sudo docker-compose -f docker-compose-postgres.yaml logs -f"
echo "============================================================"

# Prompt user to edit .env file
read -p "Would you like to edit the .env file now? (y/n): " edit_env
if [[ $edit_env == "y" ]]; then
    nano ~/n8n-traefik/.env
    
    # Ask if user wants to start the containers
    read -p "Would you like to start the containers now? (y/n): " start_containers
    if [[ $start_containers == "y" ]]; then
        cd ~/n8n-traefik
        sudo docker-compose -f docker-compose-postgres.yaml up -d
        echo "Containers started in detached mode."
    else
        echo "You can start the containers later with: cd ~/n8n-traefik && sudo docker-compose -f docker-compose-postgres.yaml up -d"
    fi
else
    echo "Remember to customize the .env file before starting the service!"
fi
