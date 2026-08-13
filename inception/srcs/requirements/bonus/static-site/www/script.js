/* Inception AI — Chatbot Engine */


(function () {
    'use strict';

    const chat = document.getElementById('chat');
    const form = document.getElementById('input-form');
    const input = document.getElementById('input');
    const sendBtn = document.getElementById('send-btn');
    const clearBtn = document.getElementById('clear-btn');
    const welcome = document.getElementById('welcome');

    // ── Knowledge Base{LLm dyal l3bar hhhhhhhh} ─────────────────────────────────────────
    const KB = [
        {
            keys: ['inception', 'what is inception', 'project', 'about'],
            answer: `**Inception** is a 42 School system administration project where you build a complete infrastructure using **Docker Compose**.

You set up multiple services — each in its own container, each built from scratch using **Alpine Linux** (or Debian). No pre-built Docker Hub images allowed.

The core services include:
• \`Nginx\` with TLS v1.2/1.3
• \`WordPress\` + PHP-FPM
• \`MariaDB\` for the database

Bonus services can include Redis, FTP, Adminer, a static site, and more.`
        },
        {
            keys: ['docker', 'container', 'what is docker'],
            answer: `**Docker** is a platform for building, shipping, and running applications inside isolated *containers*.

In Inception, every service runs in its own Docker container:
• Each container is built from a custom \`Dockerfile\`
• All containers are orchestrated via \`docker-compose.yml\`
• Containers communicate over a shared Docker network
• Persistent data is stored in Docker **volumes**

Key commands:
\`\`\`
docker compose up -d --build
docker compose down
docker compose logs -f
\`\`\``
        },
        {
            keys: ['nginx', 'web server', 'reverse proxy', 'tls', 'ssl', 'https'],
            answer: `**Nginx** serves as the entry point to the entire infrastructure.

In this project, Nginx is configured as:
• A **TLS terminator** — only TLSv1.2 and TLSv1.3 are accepted
• A **reverse proxy** — forwards PHP requests to WordPress on port 9000
• The **only container** with an exposed port (443)

The SSL certificate is self-signed and generated during container build using \`openssl\`.

Config location: \`/etc/nginx/nginx.conf\`
Listens on: **port 443** (HTTPS only)`
        },
        {
            keys: ['wordpress', 'wp', 'php', 'cms', 'wp-cli'],
            answer: `**WordPress** runs with **PHP-FPM** (FastCGI Process Manager) — no Apache involved.

Setup is fully automated using **WP-CLI**:
• Downloads WordPress core
• Creates \`wp-config.php\` with DB credentials
• Installs WordPress (site title, admin user)
• Creates a second regular user

PHP-FPM listens on **port 9000** and communicates with Nginx over the Docker network.

WordPress files live on a shared Docker volume so they persist across restarts.`
        },
        {
            keys: ['mariadb', 'database', 'db', 'mysql', 'sql'],
            answer: `**MariaDB** is the relational database for WordPress.

The setup script (\`init_db.sh\`) handles:
• Creating the WordPress database
• Creating a database user with proper privileges
• Setting the root password
• All credentials come from **Docker secrets** or environment variables

Data is stored in a persistent Docker **volume**, so it survives container restarts.

Listens on: **port 3306** (internal network only)`
        },
        {
            keys: ['redis', 'cache', 'caching', 'object cache'],
            answer: `**Redis** is an in-memory key-value store used for **WordPress object caching**.

Benefits:
• Reduces database queries dramatically
• Speeds up page loads
• Stores session data and transients in memory

In this project, Redis connects to WordPress via port **6379** on the internal Docker network. The WordPress Redis plugin handles the integration.`
        },
        {
            keys: ['ftp', 'vsftpd', 'file transfer'],
            answer: `**vsftpd** (Very Secure FTP Daemon) provides FTP access to the WordPress volume.

Configuration highlights:
• Runs in **passive mode** for Docker compatibility
• Connected to the WordPress files volume
• Allows uploading/managing WordPress files remotely
• Uses a dedicated FTP user

This is a **bonus service** that demonstrates additional container orchestration.`
        },
        {
            keys: ['adminer', 'database management', 'phpmyadmin'],
            answer: `**Adminer** is a lightweight database management tool — a single PHP file that provides a full GUI for MariaDB.

Features:
• Browse tables, run SQL queries
• Import/export databases
• Manage users and permissions
• Much lighter than phpMyAdmin

It connects to MariaDB over the internal Docker network on port 3306.`
        },
        {
            keys: ['static', 'static site', 'bonus site', 'this site'],
            answer: `**This static site** is one of the bonus services! It runs on its own Nginx container (Alpine Linux) and serves pure HTML, CSS, and JavaScript.

It's a chatbot interface (the one you're using right now!) that answers questions about the Inception project. No backend, no API calls — just a smart frontend with pattern matching.

It demonstrates that not every container needs to be complex — sometimes simplicity is the point.`
        },
        {
            keys: ['volume', 'volumes', 'persistent', 'storage', 'data'],
            answer: `Docker **volumes** provide persistent storage that survives container restarts.

Inception uses these volumes:
• **WordPress volume** — stores WordPress files (\`/var/www/html\`)
• **Database volume** — stores MariaDB data (\`/var/lib/mysql\`)
• **Logs volume** (optional) — for centralized logging

Volumes are defined in \`docker-compose.yml\` and mounted into containers at specific paths. They're stored on the host machine under \`/home/<login>/data/\`.`
        },
        {
            keys: ['network', 'docker network', 'communication'],
            answer: `All containers communicate over a single **Docker bridge network** (commonly named \`inception_net\`).

This means:
• Containers reference each other by **service name** (e.g., \`mariadb\`, \`wordpress\`)
• No need for IP addresses — Docker DNS handles resolution
• Only **Nginx** exposes a port to the host (443)
• All other communication is internal

This is defined in the \`networks\` section of \`docker-compose.yml\`.`
        },
        {
            keys: ['dockerfile', 'build', 'image', 'alpine', 'debian'],
            answer: `Every service has its own **Dockerfile** that builds a custom image.

Rules for Inception:
• Must use **Alpine Linux** or **Debian** as the base image
• **No pre-built images** from Docker Hub (except the base OS)
• Each Dockerfile installs packages, copies configs, and sets the entrypoint
• Build context is set in \`docker-compose.yml\`

Example structure:
\`\`\`
FROM alpine:3.19
RUN apk add --no-cache nginx
COPY conf/nginx.conf /etc/nginx/nginx.conf
EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]
\`\`\``
        },
        {
            keys: ['compose', 'docker-compose', 'docker compose', 'yml', 'yaml', 'orchestration'],
            answer: `**docker-compose.yml** is the orchestration file that ties everything together.

It defines:
• **Services** — each container and its build context
• **Networks** — the shared Docker network
• **Volumes** — persistent storage mounts
• **Environment variables** — configuration for each service
• **Dependencies** — startup order (\`depends_on\`)
• **Restart policies** — \`restart: unless-stopped\`

Start everything: \`docker compose up -d --build\`
Stop everything: \`docker compose down\`
View logs: \`docker compose logs -f <service>\``
        },
        {
            keys: ['secrets', 'credentials', 'password', 'security', 'env'],
            answer: `Sensitive data is managed through **Docker secrets** or \`.env\` files.

Common secrets include:
• \`db_password\` — MariaDB user password
• \`db_root_password\` — MariaDB root password
• \`credentials\` — WordPress admin credentials

Secrets are mounted as files in \`/run/secrets/\` inside containers. This is more secure than environment variables since they don't appear in \`docker inspect\` output.

**Never commit secrets to Git!** They should be in \`.gitignore\`.`
        },
        {
            keys: ['42', 'school', '42 school', 'forty two'],
            answer: `**42 School** is a tuition-free, peer-to-peer coding school with:

• No teachers or traditional classes
• Project-based learning (like Inception!)
• A peer-evaluation system — students grade each other
• Campuses worldwide (Paris, Seoul, Tokyo, São Paulo, etc.)

Inception is one of the later projects in the **Common Core** curriculum, testing your understanding of system administration, Docker, and infrastructure.`
        },
        {
            keys: ['makefile', 'make', 'build commands'],
            answer: `The **Makefile** provides convenient shortcuts for managing the infrastructure.

Typical targets:
\`\`\`
make        # Build and start all containers
make down   # Stop and remove containers
make clean  # Remove containers + volumes
make fclean # Full cleanup (images, volumes, networks)
make re     # Rebuild from scratch
\`\`\`

It usually wraps \`docker compose\` commands and may also handle creating required directories or generating secrets.`
        },
        {
            keys: ['architecture', 'diagram', 'flow', 'how it works', 'overview'],
            answer: `Here's how the infrastructure flows:

\`\`\`
Client (Browser)
    │
    ▼ HTTPS :443
┌─────────┐
│  NGINX   │ ← TLS termination
└────┬────┘
     │ FastCGI :9000
     ▼
┌──────────┐     ┌──────────┐
│ WORDPRESS │────▶│ MARIADB  │
└─────┬────┘     └──────────┘
      │               :3306
      ▼
┌─────────┐
│  REDIS   │ ← Object cache
└─────────┘
    :6379
\`\`\`

Bonus: FTP, Adminer, and this Static Site run alongside as additional containers.`
        },
        {
            keys: ['help', 'commands', 'what can you do', 'topics'],
            answer: `I can answer questions about the **Inception project**. Try asking about:

• **Docker** — containers, images, Dockerfiles
• **Services** — Nginx, WordPress, MariaDB, Redis, FTP, Adminer
• **Architecture** — how services communicate
• **Volumes** — persistent data storage
• **Networks** — container networking
• **Docker Compose** — orchestration
• **Secrets** — credential management
• **Makefile** — build commands
• **42 School** — about the school

Just type your question!`
        },
        {
            keys: ['hello', 'hi', 'hey', 'greetings', 'sup'],
            answer: `Hey! I'm **Inception AI** — your guide to the 42 Inception project.

Ask me anything about Docker, the services, architecture, configuration, or how it all fits together. I'm here to help!`
        },
        {
            keys: ['thanks', 'thank you', 'thx', 'ty'],
            answer: `You're welcome! If you have more questions about Inception, just ask.`
        },
        {
            keys: ['port', 'ports', 'exposed'],
            answer: `In Inception, only **one port** is exposed to the outside world:

• **443** (HTTPS) — handled by Nginx

Internal ports (container-to-container only):
• **9000** — WordPress PHP-FPM
• **3306** — MariaDB
• **6379** — Redis
• **21/pasv** — FTP (if exposed as bonus)
• **3000** — Static site (this chatbot!)
• **8080** — Adminer

All internal communication happens over the Docker network.`
        },
        {
            keys: ['restart', 'policy', 'crash', 'recovery'],
            answer: `All containers use the restart policy: **\`unless-stopped\`**

This means:
• Containers automatically restart if they crash
• They restart when Docker daemon starts (e.g., after reboot)
• They only stay stopped if you explicitly stop them with \`docker compose down\`

This is set in \`docker-compose.yml\` for each service:
\`\`\`yaml
restart: unless-stopped
\`\`\``
        }
    ];

    const fallback = `I'm not sure about that specific topic. Try asking about:
• **Docker** & containers
• **Nginx**, **WordPress**, **MariaDB**, **Redis**
• **Architecture** & networking
• **Volumes**, **secrets**, **Makefile**

Or type **help** to see all topics!`;

    // ── Matching Engine ────────────────────────────────────────
    function findAnswer(input) {
        const q = input.toLowerCase().trim();

        // Exact / substring match
        let bestScore = 0;
        let bestAnswer = null;

        for (const entry of KB) {
            for (const key of entry.keys) {
                if (q === key) return entry.answer;
                if (q.includes(key) || key.includes(q)) {
                    const score = key.length;
                    if (score > bestScore) {
                        bestScore = score;
                        bestAnswer = entry.answer;
                    }
                }
            }
        }

        if (bestAnswer) return bestAnswer;

        // Word overlap matching
        const words = q.split(/\s+/).filter(w => w.length > 2);
        bestScore = 0;
        for (const entry of KB) {
            let score = 0;
            for (const key of entry.keys) {
                for (const word of words) {
                    if (key.includes(word)) score += word.length;
                }
            }
            if (score > bestScore) {
                bestScore = score;
                bestAnswer = entry.answer;
            }
        }

        return bestScore > 3 ? bestAnswer : fallback;
    }

    // ── Formatting ─────────────────────────────────────────────
    function formatText(text) {
        return text
            .replace(/```([\s\S]*?)```/g, '<pre>$1</pre>')
            .replace(/`([^`]+)`/g, '<code>$1</code>')
            .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
            .replace(/\*([^*]+)\*/g, '<em>$1</em>')
            .replace(/^• (.+)$/gm, '<span style="display:block;padding-left:1em;">• $1</span>')
            .replace(/\n/g, '<br>');
    }

    // ── Message Rendering ──────────────────────────────────────
    function addMessage(text, type) {
        if (welcome) welcome.remove();

        const div = document.createElement('div');
        div.className = `msg ${type}`;

        const avatarLabel = type === 'user' ? 'U' : 'I';
        div.innerHTML = `
            <div class="msg-avatar">${avatarLabel}</div>
            <div class="msg-body">
                <div class="msg-name">${type === 'user' ? 'You' : 'Inception AI'}</div>
                <div class="msg-text">${type === 'user' ? escapeHtml(text) : text}</div>
            </div>`;

        chat.appendChild(div);
        chat.scrollTop = chat.scrollHeight;
        return div;
    }

    function addTypingIndicator() {
        if (welcome) welcome.remove();

        const div = document.createElement('div');
        div.className = 'msg bot';
        div.id = 'typing';
        div.innerHTML = `
            <div class="msg-avatar">I</div>
            <div class="msg-body">
                <div class="msg-name">Inception AI</div>
                <div class="msg-text"><div class="typing-dots"><span></span><span></span><span></span></div></div>
            </div>`;

        chat.appendChild(div);
        chat.scrollTop = chat.scrollHeight;
        return div;
    }

    // ── Typing Animation ───────────────────────────────────────
    function typeResponse(rawText) {
        const formatted = formatText(rawText);
        const indicator = addTypingIndicator();

        const delay = 400 + Math.random() * 400;
        setTimeout(() => {
            indicator.remove();
            const msgEl = addMessage(formatted, 'bot');
            // Smooth entrance is handled by CSS animation
        }, delay);
    }

    // ── Send Handler ───────────────────────────────────────────
    function send(text) {
        if (!text.trim()) return;

        addMessage(text, 'user');
        input.value = '';
        sendBtn.disabled = true;

        const answer = findAnswer(text);
        typeResponse(answer);
    }

    // ── Events ─────────────────────────────────────────────────
    form.addEventListener('submit', (e) => {
        e.preventDefault();
        send(input.value);
    });

    input.addEventListener('input', () => {
        sendBtn.disabled = !input.value.trim();
    });

    clearBtn.addEventListener('click', () => {
        chat.innerHTML = `
            <div class="welcome" id="welcome">
                <div class="welcome-icon">
                    <svg viewBox="0 0 48 48" fill="none">
                        <rect width="48" height="48" rx="12" fill="#FF6B35" opacity="0.1"/>
                        <rect x="4" y="4" width="40" height="40" rx="10" fill="#FF6B35" opacity="0.15"/>
                        <path d="M16 14h3v20h-3zM23 19h9v3h-9zM23 27h9v3h-9z" fill="#FF6B35"/>
                    </svg>
                </div>
                <h1>Inception AI</h1>
                <p>Ask me anything about the 42 Inception project — Docker, services, configuration, architecture, and more.</p>
                <div class="suggestions">
                    <button class="suggestion" data-q="What is the Inception project?">What is the Inception project?</button>
                    <button class="suggestion" data-q="Explain the Docker architecture">Explain the Docker architecture</button>
                    <button class="suggestion" data-q="What services are running?">What services are running?</button>
                    <button class="suggestion" data-q="How does Nginx work in this setup?">How does Nginx work here?</button>
                    <button class="suggestion" data-q="What are Docker volumes?">What are Docker volumes?</button>
                    <button class="suggestion" data-q="How is WordPress configured?">How is WordPress configured?</button>
                </div>
            </div>`;
        bindSuggestions();
        input.focus();
    });

    // Suggestion buttons (delegated)
    function bindSuggestions() {
        document.querySelectorAll('.suggestion').forEach(btn => {
            btn.addEventListener('click', () => send(btn.dataset.q));
        });
    }
    bindSuggestions();

    // ── Utility ────────────────────────────────────────────────
    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

})();
