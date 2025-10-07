# n8n Auto-Installer for Ubuntu (Docker + optional Cloudflare Tunnel)

A single Bash installer that:
- updates & upgrades Ubuntu (22.04 / 24.04),
- installs Docker Engine (stable / v2 line) and docker compose plugin,
- deploys n8n in Docker Compose,
- generates a secure random admin password and logs it to console + `/var/log/n8n-install.log`,
- optionally installs & configures Cloudflare Tunnel for HTTPS.

> Author: Draatman ZS1TAS  
> License: MIT (see `LICENSE`)

---

## Quick start (interactive)

1. Create a fresh Ubuntu 22.04 / 24.04 VM.
2. Upload the script `install-n8n.sh` to the VM.
3. Make executable and run:
```bash
chmod +x install-n8n.sh
sudo ./install-n8n.sh
