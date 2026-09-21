#!/usr/bin/env bash

set -e

# ============================================================
# Symfony Blog - Partie 3/8
# Création des fichiers Docker
#
# IMPORTANT :
# Ce script :
#   - NE fait aucune installation
#   - NE lance aucun conteneur
#   - NE lance aucun docker compose
#   - NE crée aucun cluster
#
# Il crée uniquement les fichiers Docker.
# ============================================================

PROJECT_DIR="${HOME}/symfony-blog"

echo "=============================================="
echo " Symfony Blog - Fichiers Docker"
echo "=============================================="

mkdir -p "$PROJECT_DIR"

cd "$PROJECT_DIR"

# ============================================================
# 1. Dockerfile principal
# ============================================================

cat > Dockerfile <<'EOF'
# ============================================================
# Symfony Blog - Image PHP
# ============================================================

FROM php:8.2-fpm

# ------------------------------------------------------------
# Variables
# ------------------------------------------------------------

ENV APP_ENV=prod

WORKDIR /var/www/html

# ------------------------------------------------------------
# Dépendances système
# ------------------------------------------------------------

RUN apt-get update \
    && apt-get install -y \
        git \
        unzip \
        libicu-dev \
        libpq-dev \
        libzip-dev \
        libonig-dev \
        curl \
    && docker-php-ext-install \
        intl \
        pdo \
        pdo_pgsql \
        opcache \
        zip \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Composer
# ------------------------------------------------------------

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# ------------------------------------------------------------
# Dépendances PHP
# ------------------------------------------------------------

COPY composer.json composer.lock* ./

RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader \
    --no-scripts

# ------------------------------------------------------------
# Application
# ------------------------------------------------------------

COPY . .

# ------------------------------------------------------------
# Permissions Symfony
# ------------------------------------------------------------

RUN mkdir -p var/cache var/log \
    && chown -R www-data:www-data var

# ------------------------------------------------------------
# OPcache
# ------------------------------------------------------------

RUN docker-php-ext-enable opcache

# ------------------------------------------------------------
# Port PHP-FPM
# ------------------------------------------------------------

EXPOSE 9000

CMD ["php-fpm"]
EOF

# ============================================================
# 2. Configuration PHP
# ============================================================

mkdir -p docker/php

cat > docker/php/php.ini <<'EOF'
[PHP]

memory_limit = 256M

upload_max_filesize = 20M

post_max_size = 20M

max_execution_time = 30

date.timezone = Europe/Paris

display_errors = Off

log_errors = On

error_log = /proc/self/fd/2


[opcache]

opcache.enable=1

opcache.memory_consumption=128

opcache.interned_strings_buffer=16

opcache.max_accelerated_files=20000

opcache.validate_timestamps=0

opcache.revalidate_freq=0
EOF

# ============================================================
# 3. Configuration PHP-FPM
# ============================================================

cat > docker/php/www.conf <<'EOF'
[www]

user = www-data

group = www-data

listen = 9000

listen.owner = www-data

listen.group = www-data

pm = dynamic

pm.max_children = 20

pm.start_servers = 2

pm.min_spare_servers = 2

pm.max_spare_servers = 5

pm.max_requests = 500

clear_env = no
EOF

# ============================================================
# 4. Dockerfile Nginx
# ============================================================

cat > docker/nginx/Dockerfile <<'EOF'
FROM nginx:1.27-alpine

COPY default.conf /etc/nginx/conf.d/default.conf

WORKDIR /var/www/html
EOF

# ============================================================
# 5. Configuration Nginx
# ============================================================

cat > docker/nginx/default.conf <<'EOF'
server {

    listen 80;

    server_name _;

    root /var/www/html/public;

    index index.php;

    # --------------------------------------------------------
    # Health check
    # --------------------------------------------------------

    location = /health {

        access_log off;

        default_type text/plain;

        return 200 "OK\n";
    }

    # --------------------------------------------------------
    # Symfony
    # --------------------------------------------------------

    location / {

        try_files $uri /index.php$is_args$args;
    }

    # --------------------------------------------------------
    # PHP
    # --------------------------------------------------------

    location ~ ^/index\.php(/|$) {

        fastcgi_pass php:9000;

        fastcgi_split_path_info ^(.+\.php)(/.*)$;

        include fastcgi_params;

        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

        fastcgi_param DOCUMENT_ROOT $document_root;

        internal;
    }

    # --------------------------------------------------------
    # Interdire les autres fichiers PHP
    # --------------------------------------------------------

    location ~ \.php$ {

        return 404;
    }

    # --------------------------------------------------------
    # Fichiers cachés
    # --------------------------------------------------------

    location ~ /\.(?!well-known).* {

        deny all;
    }

    # --------------------------------------------------------
    # Assets
    # --------------------------------------------------------

    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2)$ {

        expires 7d;

        access_log off;
    }
}
EOF

# ============================================================
# 6. PostgreSQL
# ============================================================

mkdir -p docker/postgres

cat > docker/postgres/init.sql <<'EOF'
-- ============================================================
-- Symfony Blog
-- Initialisation PostgreSQL
-- ============================================================

-- Le schéma Doctrine sera créé par Symfony/Doctrine.
--
-- Ce fichier est volontairement minimal.
--
-- Il pourra ensuite être utilisé pour :
--   - extensions PostgreSQL
--   - utilisateurs
--   - paramètres DB
--   - initialisation spécifique
EOF

# ============================================================
# 7. Docker Compose
# ============================================================

cat > docker-compose.yml <<'EOF'
services:

  # ==========================================================
  # Nginx
  # ==========================================================

  nginx:

    build:
      context: ./docker/nginx

    container_name: symfony-blog-nginx

    ports:
      - "8080:80"

    volumes:
      - .:/var/www/html:ro

    depends_on:
      - php

    networks:
      - symfony

    restart: unless-stopped

  # ==========================================================
  # PHP / Symfony
  # ==========================================================

  php:

    build:
      context: .
      dockerfile: Dockerfile

    container_name: symfony-blog-php

    environment:

      APP_ENV: dev

      APP_DEBUG: "1"

      APP_SECRET: change-me

      DATABASE_URL: >-
        postgresql://symfony:symfony_password@database:5432/symfony
        ?serverVersion=16
        &charset=utf8

    volumes:
      - .:/var/www/html

      - symfony_var:/var/www/html/var

    depends_on:

      database:
        condition: service_healthy

    networks:
      - symfony

    restart: unless-stopped

  # ==========================================================
  # PostgreSQL
  # ==========================================================

  database:

    image: postgres:16-alpine

    container_name: symfony-blog-db

    environment:

      POSTGRES_DB: symfony

      POSTGRES_USER: symfony

      POSTGRES_PASSWORD: symfony_password

    volumes:

      - postgres_data:/var/lib/postgresql/data

      - ./docker/postgres/init.sql:/docker-entrypoint-initdb.d/init.sql:ro

    ports:
      - "5432:5432"

    healthcheck:

      test:
        [
          "CMD-SHELL",
          "pg_isready -U symfony -d symfony"
        ]

      interval: 5s

      timeout: 5s

      retries: 10

      start_period: 10s

    networks:
      - symfony

    restart: unless-stopped


# ============================================================
# Réseau
# ============================================================

networks:

  symfony:

    driver: bridge


# ============================================================
# Volumes
# ============================================================

volumes:

  postgres_data:

  symfony_var:
EOF

# ============================================================
# 8. Docker Compose production
# ============================================================

cat > docker-compose.prod.yml <<'EOF'
services:

  nginx:

    build:
      context: ./docker/nginx

    restart: always

    ports:
      - "80:80"

    volumes:
      - public_data:/var/www/html/public:ro

    depends_on:
      - php

    networks:
      - symfony

  php:

    build:
      context: .
      dockerfile: Dockerfile

    restart: always

    environment:

      APP_ENV: prod

      APP_DEBUG: "0"

      APP_SECRET: ${APP_SECRET}

      DATABASE_URL: ${DATABASE_URL}

    networks:
      - symfony

    volumes:

      - symfony_var:/var/www/html/var

  database:

    image: postgres:16-alpine

    restart: always

    environment:

      POSTGRES_DB: ${POSTGRES_DB}

      POSTGRES_USER: ${POSTGRES_USER}

      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

    volumes:

      - postgres_data:/var/lib/postgresql/data

    networks:
      - symfony

networks:

  symfony:

    driver: bridge

volumes:

  postgres_data:

  symfony_var:

  public_data:
EOF

# ============================================================
# 9. .dockerignore
# ============================================================

cat > .dockerignore <<'EOF'
.git
.github

.gitignore

.env
.env.*

vendor/
var/

node_modules/

tests/

docs/

k8s/

monitoring/

.idea/
.vscode/

*.md

docker-compose.override.yml
EOF

# ============================================================
# 10. Healthcheck Docker
# ============================================================

mkdir -p docker/healthcheck

cat > docker/healthcheck/README.md <<'EOF'
# Docker Health Checks

Les health checks seront utilisés pour vérifier :

- disponibilité de Symfony ;
- disponibilité de Nginx ;
- disponibilité de PostgreSQL ;
- récupération après panne.

Les health checks Kubernetes seront définis séparément
dans `k8s/base/probes.yaml`.
EOF

# ============================================================
# 11. Documentation Docker
# ============================================================

mkdir -p docs/devops

cat > docs/devops/docker.md <<'EOF'
# Docker

## Architecture

```text
Internet
   |
   v
 Nginx
   |
   v
 PHP-FPM / Symfony
   |
   v
PostgreSQL

Objectifs

Docker permettra :

    la reproductibilité ;

    l'isolation des services ;

    la construction d'images ;

    l'intégration CI/CD ;

    la préparation au déploiement Kubernetes.

Services
nginx

Serveur HTTP.
php

Application Symfony / PHP-FPM.
database

Base PostgreSQL.
Important

Les conteneurs ne sont pas démarrés par le script de création.
EOF
============================================================
12. Affichage
============================================================

echo
echo "=============================================="
echo " Partie 3 terminée"
echo "=============================================="

echo
echo "Fichiers Docker créés."

echo
echo "Aucun conteneur lancé."
echo "Aucune image construite."
echo "Aucune installation effectuée."

echo
echo "Pour afficher l'arborescence :"

echo
echo "cd $PROJECT_DIR"
echo "tree -a -I .git"

echo
echo "Fichiers principaux :"

echo " Dockerfile"
echo " docker-compose.yml"
echo " docker-compose.prod.yml"
echo " docker/nginx/Dockerfile"
echo " docker/nginx/default.conf"
echo " docker/php/php.ini"
echo " docker/php/www.conf"
echo " docker/postgres/init.sql"

echo
echo "=============================================="


### Ce que tu obtiens

```text
docker/
├── healthcheck/
│   └── README.md
├── nginx/
│   ├── Dockerfile
│   └── default.conf
├── php/
│   ├── php.ini
│   └── www.conf
└── postgres/
    └── init.sql

Dockerfile
docker-compose.yml
docker-compose.prod.yml
