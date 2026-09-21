#!u/bin/bash

set -e

echo "=========================================="
echo " Partie 8 - Configuration Docker"
echo "=========================================="

PROJECT_DIR="$(pwd)"

if [ ! -f "composer.json" ]; then
    echo "⚠️ Attention : composer.json n'est pas présent."
    echo "Le script prépare quand même les fichiers Docker."
fi

echo "[1/4] Création du Dockerfile PHP..."

cat > docker/php/Dockerfile <<'EOF'
FROM php:8.2-fpm-alpine

RUN apk add --no-cache \
    git \
    unzip \
    icu-dev \
    libzip-dev \
    oniguruma-dev \
    $PHPIZE_DEPS

RUN docker-php-ext-install \
    intl \
    pdo \
    pdo_mysql \
    zip \
    opcache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

RUN if [ -f composer.json ]; then \
        composer install \
        --no-interaction \
        --prefer-dist \
        --optimize-autoloader; \
    fi

RUN chown -R www-data:www-data /var/www/html

USER www-data

EXPOSE 9000

CMD ["php-fpm"]
EOF


echo "[2/4] Création du Dockerfile principal..."

cat > Dockerfile <<'EOF'
FROM php:8.2-fpm-alpine

RUN apk add --no-cache \
    git \
    unzip \
    icu-dev \
    libzip-dev \
    oniguruma-dev \
    nginx \
    $PHPIZE_DEPS

RUN docker-php-ext-install \
    intl \
    pdo \
    pdo_mysql \
    zip \
    opcache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

RUN if [ -f composer.json ]; then \
        composer install \
        --no-interaction \
        --prefer-dist \
        --optimize-autoloader; \
    fi

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

CMD ["php-fpm"]
EOF


echo "[3/4] Création de la configuration Nginx..."

cat > docker/nginx/nginx.conf <<'EOF'
server {
    listen 80;
    server_name _;

    root /var/www/html/public;
    index index.php;

    location / {
        try_files $uri /index.php$is_args$args;
    }

    location ~ ^/index\.php(/|$) {
        fastcgi_pass php:9000;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;

        include fastcgi_params;

        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $document_root;

        internal;
    }

    location ~ \.php$ {
        return 404;
    }

    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2)$ {
        expires 7d;
        access_log off;
    }
}
EOF


echo "[4/4] Création du docker-compose.yml..."

cat > docker-compose.yml <<'EOF'
services:

  php:
    build:
      context: .
      dockerfile: docker/php/Dockerfile

    container_name: symfony-blog-php

    volumes:
      - ./:/var/www/html

    environment:
      APP_ENV: dev

    depends_on:
      - database

  nginx:
    image: nginx:alpine

    container_name: symfony-blog-nginx

    ports:
      - "8080:80"

    volumes:
      - ./:/var/www/html
      - ./docker/nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro

    depends_on:
      - php

  database:
    image: mysql:8.0

    container_name: symfony-blog-db

    environment:
      MYSQL_DATABASE: symfony
      MYSQL_USER: symfony
      MYSQL_PASSWORD: symfony_password
      MYSQL_ROOT_PASSWORD: root_password

    ports:
      - "3306:3306"

    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
EOF


echo ""
echo "=========================================="
echo " Partie 8 terminée"
echo "=========================================="
echo ""
echo "Fichiers Docker créés :"
echo ""
echo "  Dockerfile"
echo "  docker/php/Dockerfile"
echo "  docker/nginx/nginx.conf"
echo "  docker-compose.yml"
echo ""
echo "⚠️ Aucun conteneur n'a été lancé."
echo "⚠️ Aucun cluster Kubernetes n'a été créé."
echo ""
echo "Prochaine étape : tester la configuration Docker."
