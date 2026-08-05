<div align="center">

# 🐳 Inception — 42 School Project

**A fully Dockerized infrastructure built from scratch**

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![NGINX](https://img.shields.io/badge/NGINX-009639?style=for-the-badge&logo=nginx&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-21759B?style=for-the-badge&logo=wordpress&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)
![Alpine](https://img.shields.io/badge/Alpine_Linux-0D597F?style=for-the-badge&logo=alpine-linux&logoColor=white)


</div>

---

## Table of Contents

- [About the Project](#about-the-project)
- [Overview](#overview)
- [Services](#services)
  - [Mandatory Services](#mandatory-services)
  - [Bonus Services](#bonus-services)
- [Project Structure](#project-structure)
- [Concepts Explained](#concepts-explained)
  - [Docker vs Virtual Machines](#docker-vs-virtual-machines)
  - [Docker Networks](#docker-networks)
  - [Docker Volumes vs Bind Mounts](#docker-volumes-vs-bind-mounts)
  - [Secrets vs Environment Variables](#secrets-vs-environment-variables)
  - [Why Alpine Linux?](#why-alpine-linux)
- [TLS / SSL](#tls--ssl)
- [How Services Communicate](#how-services-communicate)
- [Common Issues & Debugging](#common-issues--debugging)
- [Resources](#resources)

---

## About the Project

**Inception** is a 1337/42 schools system administration project. The goal is to build a small but complete web infrastructure using **Docker Compose**, where every service runs in its own container and built all from custom Dockerfiles using **Alpine** or **Debian** as the base image.

So this not pulling pre-configured images from Docker Hub but its about building each service from scratch, and orchestrating everything cleanly with `docker-compose`.

Key objectives:
- Build custom Docker images (no pre-built WordPress/NGINX/MariaDB images allowed)
- Use Docker Compose for orchestration
- Implement proper secret management
- Persist data using bind mounts
- Secure communications with TLS

---

## Overview

```
                        ┌─────────────────────────────────────┐
                        │           Host Machine              │
                        │                                     │
  Browser (HTTPS) ──────►  NGINX (:443)                       │
                        │     │                               │
                        │     ├──► WordPress (PHP-FPM :9000)  │
                        │     │        │                      │
                        │     │        └──► MariaDB (:3306)   │
                        │     │        │                      │
                        │     │        └──► Redis (:6379)     │
                        │     │                               │
                        │     ├──► Adminer (:8080)            │
                        │     ├──► Redis Commander (:8081)    │
                        │     └──► Static Website (:80)       │
                        │                                     │
                        │  FTP Server (:21)                   │
                        └─────────────────────────────────────┘

All containers run on: inception_network (bridge)
Data is persisted at: /home/user/data/
```

---

## Services

### Mandatory Services

#### NGINX
- Acts as the **reverse proxy** and sole entry point to the infrastructure
- Configured to only accept **TLSv1.2 and TLSv1.3** connections (HTTP is not served)
- Listens on port **443**
- Forwards PHP requests to WordPress via FastCGI (port 9000)
- Self-signed SSL certificate generated at container startup

#### WordPress
- Runs **PHP-FPM** (FastCGI Process Manager) — no Apache
- CMS for managing web content
- Connects to MariaDB for persistent storage
- Connects to Redis for object caching (bonus)
- WordPress CLI (`wp-cli`) is used in the entrypoint script for automated setup
- Does **not** expose a port to the host — only NGINX reaches it

#### MariaDB
- The **relational database** for WordPress
- Stores all WordPress posts, users, settings, etc.
- Database, user, and password are created automatically via the entrypoint script
- Data persisted via a bind mount to `/home/riel-fas/data/mariadb`

---

### Bonus Services

#### Redis
- In-memory key-value store used as a **WordPress object cache**
- Reduces database load and speeds up page delivery
- Configured in WordPress via the `WP_REDIS_HOST` environment variable

#### FTP Server
- Allows file transfer to the WordPress volume
- Points to the WordPress data directory
- Useful for directly uploading themes, plugins, and media

#### Adminer
- Lightweight **database management web UI**
- Accessible through NGINX on a dedicated path/port
- Alternative to phpMyAdmin — single PHP file, very fast

#### Redis Commander (optional choice)
- Web interface for **browsing and managing Redis data**
- Helps debug caching issues during development

#### Static Website (optional choice)
- A simple custom HTML/CSS/JS website
- Served independently by NGINX
- Demonstrates multi-site serving in a single infrastructure

---

## Project Structure

```
Inception/
│
├── Makefile                    # Build & management commands
├── .gitignore
├── README.md
├── DEV_DOC.md                  # Developer documentation
├── USER_DOC.md                 # User documentation
├── en.subject.pdf              # 42 project subject
│
├── secrets/                    # Sensitive credentials (not committed)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── ...
│
└── srcs/
    ├── docker-compose.yml      # Orchestration file
    ├── .env                    # Environment variables (not committed)
    │
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        │       └── nginx.conf
        │
        ├── wordpress/
        │   ├── Dockerfile
        │   └── tools/
        │       └── entrypoint.sh
        │
        ├── mariadb/
        │   ├── Dockerfile
        │   └── tools/
        │       └── entrypoint.sh
        │
        └── bonus/
            ├── redis/
            ├── ftp/
            ├── adminer/
            ├── redis-commander/
            └── website/
```

---

## Concepts Explained

### Docker vs Virtual Machines

Understanding why we use Docker instead of VMs is fundamental to this project.

| Feature | Virtual Machines | Docker Containers |
|---|---|---|
| **Architecture** | Emulates full hardware; runs a complete OS per VM | Virtualizes at the OS level; shares the host kernel |
| **Resources** | Heavy,  each VM has its own kernel, consumes lots of RAM/CPU | Lightweight, containers share the host kernel |
| **Startup Time** | Slow (minutes) | Fast (seconds or less) |
| **Isolation** | Strong, hardware-level isolation | Moderate, process-level isolation (namespaces + cgroups) |
| **Portability** | Harder, VM images are large and OS-dependent | Easy, images are small, portable, and reproducible |
| **Use Case** | Full OS needed, strong security boundaries | Microservices, CI/CD, development environments |

> **Summary:** Docker containers are more efficient and faster than VMs, but VMs provide stronger isolation.

---

### Docker Networks

Docker networks allow containers to communicate with each other in a controlled and isolated way.

**Why use a custom Docker network instead of the host network?**

| Docker Network (bridge) | Host Network |
|---|---|
| Containers are isolated from the host network | Container shares host's network namespace |
| Containers communicate via **container name as DNS** | No DNS must use host IPs |
| Ports are only exposed when explicitly mapped | All ports are exposed automatically |
| **Secure**  no unintended port exposure | **Less secure**  every port is accessible |
| Slightly slower (NAT layer) | Fastest (no NAT) |

In this project, all containers are connected to `inception_network`  a custom bridge network. This means:
- Containers can reach each other by name (e.g., WordPress connects to `mariadb:3306`)
- Nothing is exposed to the outside except port 443 (NGINX)

---

### Docker Volumes vs Bind Mounts

Data persistence is critical. Containers are ephemeral — when they stop, data is gone unless stored externally.

| Docker Volumes | Bind Mounts |
|---|---|
| Managed entirely by Docker | Maps a **specific host path** to a container path |
| Stored in `/var/lib/docker/volumes/` (opaque) | You control exactly where data lives on the host |
| Easier to manage via `docker volume` CLI | Harder to manage, but more transparent |
| Better for production isolation | Better for development (direct access to files) |

**This project uses Bind Mounts:**
- WordPress data → `/home/user/data/wordpress`
- MariaDB data → `/home/user/data/mariadb`

This makes data explicitly visible on the host filesystem and survives even if Docker is completely reset.

---

### Secrets vs Environment Variables

Sensitive data (passwords, tokens) should never be stored in plain environment variables.

**Why Environment Variables are risky:**
- Visible via `docker inspect <container>`
- Visible in `/proc/<pid>/environ` inside the container
- Can be accidentally logged
- Visible in shell history if typed inline

**Why Secrets are better:**
- Stored as files, mounted at `/run/secrets/<name>` inside the container
- Never appear in `docker inspect`
- Access is controlled — only the container that needs it gets it

**This project's approach:**  
Secrets are stored as text files in the `secrets/` directory and injected into containers via Docker Compose's `secrets:` directive. Entrypoint scripts read from `/run/secrets/` instead of environment variables wherever possible.

> ⚠️ The `secrets/` directory and the `.env` are listed in `.gitignore` and should **never** be committed to version control.

---

### Why Alpine Linux?

All custom images in this repo. are based on **Alpine Linux** instead of Debian.

| | Alpine Linux | Ubuntu/Debian |
|---|---|---|
| **Image size** | ~5MB base | ~70–120MB base |
| **Attack surface** | Minimal — fewer packages installed | Larger — more pre-installed tools |
| **Package manager** | `apk` | `apt` |
| **Init system** | `busybox` / `openrc` | `systemd` |
| **Performance** | Faster to pull and start | Slower |

Alpine keeps containers lean and fast by default. The tradeoff is that some packages have different names or aren't available, requiring more careful configuration.

---

## Setup & Installation

> Coming soon / refer to USER_DOC.md

---

## Makefile Commands

> Coming soon / refer to USER_DOC.md

---

## Environment Variables

> Coming soon / refer to USER_DOC.md

---

## TLS / SSL

NGINX is configured to **only accept HTTPS connections** using **TLSv1.2 and TLSv1.3**.

A **self-signed SSL certificate** is generated during the NGINX container startup using `openssl`:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/nginx.key \
  -out /etc/ssl/certs/nginx.crt \
  -subj "/C=MA/ST=Casablanca/L=Casablanca/O=42/CN=riel-fas.42.fr"
```

The NGINX config enforces TLS only:

```nginx
server {
    listen 443 ssl;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_certificate     /etc/ssl/certs/nginx.crt;
    ssl_certificate_key /etc/ssl/private/nginx.key;
    ...
}
```

> There is no plain HTTP (port 80) listener for the main site — only HTTPS.

---

## How Services Communicate

All containers are on the same custom Docker network (`inception_network`), allowing them to resolve each other by **container name**:

```
NGINX      ──FastCGI──►  wordpress:9000
WordPress  ──TCP──────►  mariadb:3306
WordPress  ──TCP──────►  redis:6379
NGINX      ──HTTP─────►  adminer:8080
NGINX      ──HTTP─────►  website:80
```

No container exposes its internal ports to the host except through NGINX (port 443) or specific explicitly mapped ports (FTP, for our example).

---

## Common Issues & Debugging

> Coming soon / refer to DEV_DOC.md

---

## Resources

### Official Documentation
- [Docker Docs](https://docs.docker.com/)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [NGINX Docs](https://nginx.org/en/docs/)
- [MariaDB Docs](https://mariadb.com/kb/en/)
- [WordPress CLI (wp-cli)](https://wp-cli.org/)
- [Redis Docs](https://redis.io/docs/)
- [Alpine Linux Packages](https://pkgs.alpinelinux.org/)

### Useful Guides
- [PHP-FPM + NGINX Setup](https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)
- [Understanding Docker Networking](https://docs.docker.com/network/)
- [WP-CLI Quick Start](https://make.wordpress.org/cli/handbook/guides/quick-start/)
- [Redis Object Cache Plugin for WP](https://wordpress.org/plugins/redis-cache/)

---
