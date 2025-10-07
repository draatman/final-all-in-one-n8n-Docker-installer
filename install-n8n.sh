#!/bin/bash
set -e

LOGFILE="/var/log/n8n-install.log"
mkdir -p "$(dirname "$LOGFILE")"

echo "=== n8n Auto-Install Script ===" | tee "$LOGFILE"

echo "Updating system..." | tee -a "$LOGFILE"
apt update && apt -y upgrade

echo "Installing prerequisites..." | tee -a "$LOGFILE"
apt -y install ca-certificates curl gnupg lsb-release

echo "Installing Docker Engine..." | tee -a "$LOGFILE"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker

echo "Creating n8n directory..." | tee -a "$LOGFILE"
mkdir -p /opt/n8n
cd /opt/n8n

# Generate random password
PASSWORD=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24)

echo "Writing docker-compose.yml..." | tee -a "$LOGFILE"
cat > docker-compose.yml <<EOF
version: "3.8"
services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=$PASSWORD
      - N8N_HOST=n8n.local
      - N8N_PORT=5678
      - WEBHOOK_URL=http://n8n.local/
      - TZ=Africa/Johannesburg
    volumes:
      - ./data:/home/node/.n8n
EOF

echo "Starting n8n..." | tee -a "$LOGFILE"
docker compose up -d

echo "Creating systemd service for n8n..." | tee -a "$LOGFILE"
cat > /etc/systemd/system/n8n.service <<'EOF'
[Unit]
Description=n8n docker service
After=network-online.target
Requires=docker.service

[Service]
Type=oneshot
WorkingDirectory=/opt/n8n
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable n8n.service

# Ask user if they want Cloudflare Tunnel
read -p "Do you want to install and configure Cloudflare Tunnel for HTTPS? (y/n): " install_cf
if [[ "$install_cf" =~ ^[Yy]$ ]]; then
    echo "Installing Cloudflare Tunnel..." | tee -a "$LOGFILE"
    curl -fsSL https://pkg.cloudflare.com/gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-main.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/ $(lsb_release -cs) main" \
      | tee /etc/apt/sources.list.d/cloudflare.list
    apt update
    apt -y install cloudflared

    read -p "Enter your Cloudflare Tunnel token: " CF_TOKEN
    read -p "Enter your DNS name for n8n (e.g. n8n.example.com): " CF_DOMAIN

    echo "Configuring Cloudflare Tunnel..." | tee -a "$LOGFILE"
    cloudflared service install "$CF_TOKEN"

    mkdir -p /etc/cloudflared
    cat > /etc/cloudflared/config.yml <<EOF
tunnel: $(basename $(dirname /etc/cloudflared/cert.pem))
credentials-file: /etc/cloudflared/cert.pem

ingress:
  - hostname: $CF_DOMAIN
    service: http://localhost:5678
  - service: http_status:404
EOF

    systemctl enable cloudflared
    systemctl restart cloudflared
    echo "Cloudflare Tunnel configured for $CF_DOMAIN" | tee -a "$LOGFILE"
fi

IP=$(hostname -I | awk '{print $1}')

echo | tee -a "$LOGFILE"
echo "=== Installation Complete ===" | tee -a "$LOGFILE"
if [[ "$install_cf" =~ ^[Yy]$ ]]; then
  echo "URL:    https://$CF_DOMAIN" | tee -a "$LOGFILE"
else
  echo "URL:    http://$IP:5678" | tee -a "$LOGFILE"
fi
echo "User:   admin" | tee -a "$LOGFILE"
echo "Pass:   $PASSWORD" | tee -a "$LOGFILE"
echo "Log:    $LOGFILE" | tee -a "$LOGFILE"
echo "===================================" | tee -a "$LOGFILE"
