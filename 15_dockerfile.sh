#!/bin/bash

set -e

echo "=========================================="
echo " Partie 15 - Dockerfile Symfony"
echo "=========================================="

mkdir -p docker/php

cat > docker/php/Dockerfile <<'EOF'
FROM php:8.2-fpm

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libicu-dev \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    && docker-php-ext-install \
    intl \
    pdo_mysql \
    zip \
    opcache \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY composer.json composer.lock ./

RUN composer install \
    --no-interaction \
    --no-progress \
    --prefer-dist

COPY . .

RUN mkdir -p var/cache var/log \
    && chown -R www-data:www-data var

USER www-data

EXPOSE 9000

CMD ["php-fpm"]
EOF

echo "✅ docker/php/Dockerfile créé."

echo ""
echo "Partie 15 terminée."

Arborescence ajoutée :

docker/
└── php/
    └── Dockerfile

Partie 16 — Docker Compose

Fichier : partie16_docker_compose.sh

Cette partie prépare l'environnement local :

Symfony
   │
   ▼
PHP-FPM
   │
   ▼
MySQL

#!/bin/bash

set -e

echo "=========================================="
echo " Partie 16 - Docker Compose"
echo "=========================================="

cat > docker-compose.yml <<'EOF'
services:

  app:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
    container_name: symfony-blog-app
    working_dir: /var/www/html
    volumes:
      - .:/var/www/html
    environment:
      APP_ENV: dev
      DATABASE_URL: mysql://symfony:symfony@database:3306/symfony?serverVersion=8.0
    depends_on:
      database:
        condition: service_healthy

  nginx:
    image: nginx:alpine
    container_name: symfony-blog-nginx
    ports:
      - "8080:80"
    volumes:
      - .:/var/www/html:ro
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - app

  database:
    image: mysql:8.0
    container_name: symfony-blog-db
    environment:
      MYSQL_DATABASE: symfony
      MYSQL_USER: symfony
      MYSQL_PASSWORD: symfony
      MYSQL_ROOT_PASSWORD: root
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  mysql_data:
EOF

mkdir -p docker/nginx

cat > docker/nginx/default.conf <<'EOF'
server {
    listen 80;
    server_name localhost;

    root /var/www/html/public;
    index index.php;

    location / {
        try_files $uri /index.php$is_args$args;
    }

    location ~ ^/index\.php(/|$) {
        fastcgi_pass app:9000;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;

        include fastcgi_params;

        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $document_root;
    }

    location ~ \.php$ {
        return 404;
    }
}
EOF

echo "=========================================="
echo " Partie 16 terminée"
echo "=========================================="

echo ""
echo "Fichiers créés :"
echo "├── docker-compose.yml"
echo "└── docker/"
echo "    └── nginx/"
echo "        └── default.conf"
echo ""
echo "⚠️ Aucun conteneur n'a été démarré."
echo "⚠️ Aucun cluster Kubernetes n'a été créé."

Architecture préparée :

                localhost:8080
                      │
                      ▼
                   NGINX
                      │
                      ▼
                 PHP-FPM
                      │
                      ▼
                  Symfony
                      │
                      ▼
                    MySQL

Partie 17 — Configuration Symfony + MySQL

Fichier : partie17_configuration_db.sh

Cette partie prépare la configuration de la base pour l'environnement Docker.

#!/bin/bash

set -e

echo "=========================================="
echo " Partie 17 - Symfony + MySQL"
echo "=========================================="

echo "[1/3] Vérification de .env..."

if [ ! -f ".env" ]; then
    echo "❌ .env introuvable."
    exit 1
fi

echo "✅ .env trouvé."

echo "[2/3] Création du fichier .env.local..."

cat > .env.local <<'EOF'
APP_ENV=dev
APP_DEBUG=1

DATABASE_URL="mysql://symfony:symfony@database:3306/symfony?serverVersion=8.0"
EOF

echo "✅ .env.local créé."

echo "[3/3] Création d'un exemple de configuration..."

cat > .env.local.example <<'EOF'
APP_ENV=dev
APP_DEBUG=1

DATABASE_URL="mysql://symfony:symfony@database:3306/symfony?serverVersion=8.0"
EOF

echo "✅ .env.local.example créé."

echo ""
echo "=========================================="
echo " Partie 17 terminée"
echo "=========================================="

echo ""
echo "Configuration :"
echo "Symfony → database:3306 → MySQL"
echo ""
echo "⚠️ .env.local contient des identifiants locaux."
echo "⚠️ Ne pas versionner .env.local."
echo "⚠️ Aucun conteneur n'a été démarré."
echo "⚠️ Aucun cluster Kubernetes n'a été créé."

Après ces 3 parties

Ton projet commence à avoir cette structure :

symfony-blog/
│
├── docker/
│   ├── nginx/
│   │   └── default.conf
│   └── php/
│       └── Dockerfile
│
├── tests/
│   ├── Unit/
│   ├── Functional/
│   ├── Integration/
│   └── Performance/
│
├── scripts/
│   ├── smoke-test.sh
│   ├── health-check.sh
│   └── check-application.sh
│
├── docker-compose.yml
├── .env.local
├── .env.local.example
└── ...
