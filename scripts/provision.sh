#!/bin/bash
set -euo pipefail

# 1. ops group
if getent group ops > /dev/null 2>&1; then
    echo "ops group already exists, skipping"
else
    sudo groupadd ops
    echo "created ops group"
fi

# 2. deploy user
if id deploy > /dev/null 2>&1; then
    echo " deploy user already exists, skipping creation"
else
    sudo useradd -m -d /home/deploy -s /bin/bash deploy
    echo "created deploy user"
fi

# 3. deploy is a member of ops
if getent group ops | grep -q '\bdeploy\b'; then
    echo "deploy already in ops group, skipping"
else
    sudo usermod -aG ops deploy
    echo "added deploy to ops group"
fi

# 4. deployment directory: /opt/kente-retail/app, deploy:deploy, 750
sudo mkdir -p /opt/kente-retail/app
sudo chown -R deploy:deploy /opt/kente-retail
sudo chmod -R 750 /opt/kente-retail
echo "deployment directory ready: /opt/kente-retail/app (deploy:deploy, 750)"

# 5. hostname:kente-app-staging01, persisted
sudo hostnamectl set-hostname kente-app-staging01

if grep -q "kente-app-staging01" /etc/hosts; then
    echo "/etc/hosts already has hostname entry, skipping"
else
    echo "127.0.1.1 kente-app-staging01" | sudo tee -a /etc/hosts > /dev/null
    echo "added hostname entry to /etc/hosts"
fi

sudo sed -i 's/^preserve_hostname: false/preserve_hostname: true/' /etc/cloud/cloud.cfg
echo "added hostname set and persisted: kente-app-staging01"

# 6. Node.js 20.x
if command -v node > /dev/null 2>&1; then
    echo "node already installed ($(node --version)), skipping"
else
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
    echo "installed node $(node --version)"
fi

# 7. system service
sudo  tee /etc/systemd/system/kente-order-service.service > /dev/null <<'EOF'
[Unit]
Description=Kente Retail Order Service
After=network.target

[Service]
Type=simple
User=deploy
Group=deploy
WorkingDirectory=/opt/kente-retail/app
ExecStart=/usr/bin/node src/index.js
Environment=PORT=8080
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now kente-order-service
echo "kente-order-service enabled and started"