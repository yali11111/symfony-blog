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
