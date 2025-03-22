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

# Supabase connection details (if using Supabase instead of local Postgres)
# SUPABASE_HOST=your-project-ref.supabase.co
# SUPABASE_PORT=5432
# SUPABASE_DATABASE=postgres
# SUPABASE_USER=postgres
# SUPABASE_PASSWORD=your-database-password
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
