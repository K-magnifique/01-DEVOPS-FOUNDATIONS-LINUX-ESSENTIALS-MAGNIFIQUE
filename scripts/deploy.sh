#!/bin/bash
set -euo pipefail

sudo -u deploy git -C /opt/kente-retail/app pull origin main
sudo chown -R deploy:deploy /opt/kente-retail
sudo chmod -R 750 /opt/kente-retail
sudo systemctl restart kente-order-service

echo "Deployed latest main and restarted kente-order-service"