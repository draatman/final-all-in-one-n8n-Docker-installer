# n8n Auto-Installer for Ubuntu (with optional Cloudflare Tunnel)

A single-script installer that provisions Docker (Docker Engine v2), Docker Compose, and a containerised **n8n** instance on Ubuntu 22.04 / 24.04.  
Generates a secure random admin password, logs credentials to console and `/var/log/n8n-install.log`. Optionally installs & configures **Cloudflare Tunnel** (cloudflared) for HTTPS.

> Unapologetically nerdy, intentionally practical. Use on fresh VMs or templates.

---

## Contents

- `install-n8n.sh` — main installer script (interactive by default)
- `LICENSE` — MIT
- `.gitignore` — suggested
- `README.md` — this file

---

## Quick start (interactive)

1. Upload `install-n8n.sh` to a
