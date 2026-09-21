#!/bin/bash

set -e

echo "=========================================="
echo " Partie 19 - GitHub Actions CI"
echo "=========================================="

mkdir -p .github/workflows

cat > .github/workflows/ci.yml <<'EOF'
name: Symfony Blog - CI

on:
  push:
    branches:
      - main
      - develop

  pull_request:
    branches:
      - main
      - develop

jobs:

  tests:

    runs-on: ubuntu-latest

    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: symfony_test
          MYSQL_USER: symfony
          MYSQL_PASSWORD: symfony
        ports:
          - 3306:3306
        options: >-
          --health-cmd="mysqladmin ping -h 127.0.0.1 -uroot -proot"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=5

    steps:

      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          extensions: mbstring, intl, pdo_mysql
          coverage: none

      - name: Install dependencies
        run: composer install --no-interaction --prefer-dist

      - name: Configure environment
        run: |
          echo 'APP_ENV=test' > .env.test.local
          echo 'APP_DEBUG=1' >> .env.test.local
          echo 'DATABASE_URL="mysql://symfony:symfony@127.0.0.1:3306/symfony_test?serverVersion=8.0"' >> .env.test.local

      - name: Run PHPUnit
        run: php bin/phpunit
EOF

echo ""
echo "=========================================="
echo " Partie 19 terminée"
echo "=========================================="
echo ""
echo "Pipeline créée :"
echo ".github/workflows/ci.yml"
echo ""
echo "⚠️ La pipeline sera exécutée par GitHub."
echo "⚠️ Aucun cluster Kubernetes n'est utilisé."
