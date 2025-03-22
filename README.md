# n8n Installation Guide for Linux VPS

This guide walks you through setting up n8n on a Linux VPS using Docker, Docker Compose, and Traefik for SSL termination.

## Prerequisites

- A Linux VPS (Ubuntu/Debian recommended)
- SSH access to your VPS with sudo privileges
- A domain name pointing to your VPS
- Basic familiarity with command line

## Step 1: Download and Run the Installation Script

Download the installation script directly from GitHub, make the script executable and execute the script:

```bash
curl -sSL https://raw.githubusercontent.com/dennisrongo/n8n-scripts/refs/heads/master/n8n-install.sh -o n8n-install.sh && chmod +x n8n-install.sh && ./n8n-install.sh
```

The script will:
- Install Docker and Docker Compose
- Create a project directory at `~/n8n-traefik`
- Set up the necessary configuration files
- Create Docker volumes for data persistence
- Prompt you to edit the `.env` file
- Offer to start the containers

## Step 2: Configure Your Environment

When prompted, edit your `.env` file with the following information:

- `DOMAIN_NAME`: Your actual domain (e.g., `yourdomain.com`)
- `SUBDOMAIN`: The subdomain for n8n (e.g., `n8n`)
- `SSL_EMAIL`: Your email address for SSL certificate registration
- `GENERIC_TIMEZONE`: Your preferred timezone

Example configuration:

```
DOMAIN_NAME=yourdomain.com
SUBDOMAIN=n8n
SSL_EMAIL=your-email@example.com
GENERIC_TIMEZONE=UTC
```

This would make n8n accessible at `https://n8n.yourdomain.com`.

## Step 3: Start the n8n Service

If you didn't start the service during the script execution, you can start it manually:

```bash
cd ~/n8n-traefik
sudo docker-compose up -d
```

The `-d` flag runs the containers in detached mode (background).

## Step 4: Verify the Installation

1. Check if the containers are running:

```bash
sudo docker-compose ps
```

2. View the logs:

```bash
sudo docker-compose logs -f
```

3. Access n8n in your web browser at `https://n8n.yourdomain.com` (replace with your actual domain).

## Step 5: Create DNS Record

1. Get your server's public IP.

2. In your domain's DNS settings:
   - Create an **A record** with:
     - **Host**: Your SUBDOMAIN from `.env` (e.g., `n8n`)
     - **Value**: Server's IP address
     - **TTL**: 3600 (default)

3. Verify setup (may take up to 1 hour):
   ```bash
   dig +short [SUBDOMAIN].[DOMAIN_NAME]  # Should return your IP
   ```

Example: If using `SUBDOMAIN=n8n` and `DOMAIN_NAME=example.com`, create an A record for `n8n` pointing to your server IP.

## Managing Your n8n Installation

### Stopping n8n

```bash
cd ~/n8n-traefik
sudo docker-compose down
```

### Restarting n8n

```bash
cd ~/n8n-traefik
sudo docker-compose restart
```

### Updating n8n

```bash
cd ~/n8n-traefik
sudo docker-compose pull
sudo docker-compose down
sudo docker-compose up -d
```

### Backup n8n Data

The data is stored in a Docker volume. To back it up:

```bash
sudo docker run --rm -v n8n_data:/source -v $(pwd):/backup alpine tar -czf /backup/n8n-backup.tar.gz -C /source .
```

This creates a backup file `n8n-backup.tar.gz` in your current directory.

## Troubleshooting

### Check Container Status

```bash
sudo docker-compose ps
```

### View Container Logs

```bash
sudo docker-compose logs -f
```

### SSL Certificate Issues

If you have SSL certificate issues:

1. Make sure your domain is properly pointing to your VPS IP address
2. Check the Traefik logs for certificate-related errors:

```bash
sudo docker-compose logs traefik
```

### Restart After Server Reboot

If your server reboots, the Docker containers should restart automatically (due to `restart: always` in the compose file). If they don't:

```bash
cd ~/n8n-traefik
sudo docker-compose up -d
```

## Security Considerations

- The n8n admin interface is publicly accessible. Consider setting up authentication.
- Review and customize the Traefik configuration for your security requirements.
- Keep your server and Docker images updated.

## Script Contents

For reference, the installation script performs the following tasks:

1. Installs Docker and Docker Compose
2. Creates configuration files (docker-compose.yaml and .env)
3. Sets up Docker volumes for data persistence
4. Guides you through configuration and startup

## Developer

This installation script and guide were created by Dennis from [Lean Code Automation](https://leancodeautomation.com/).

---

By following this guide, you should have a working n8n installation with automatic HTTPS support through Traefik. Happy automating!
