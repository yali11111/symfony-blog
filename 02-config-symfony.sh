#!/usr/bin/env bash

set -e

# ============================================================
# Symfony Blog - Partie 2/8
# Configuration Symfony
#
# IMPORTANT :
# - aucune installation
# - aucun docker
# - aucun Kubernetes
# - aucun service démarré
# - uniquement création/modification de fichiers
# ============================================================

PROJECT_DIR="${HOME}/symfony-blog"

echo "=============================================="
echo " Symfony Blog - Configuration Symfony"
echo "=============================================="

mkdir -p "$PROJECT_DIR"

cd "$PROJECT_DIR"

# ============================================================
# 1. .gitignore
# ============================================================

cat > .gitignore <<'EOF'
/.env.local
/.env.local.php
/.env.*.local

/vendor/
/var/

.phpunit.result.cache

.idea/
.vscode/

.DS_Store

docker-compose.override.yml

*.log
EOF

# ============================================================
# 2. .dockerignore
# ============================================================

cat > .dockerignore <<'EOF'
.git
.github
.gitignore

.env
.env.*
!.env.example

vendor/
var/

node_modules/

tests/
docs/

.idea/
.vscode/

*.md
EOF

# ============================================================
# 3. .env
# ============================================================

cat > .env <<'EOF'
APP_ENV=dev
APP_SECRET=change_this_secret

DATABASE_URL="postgresql://symfony:symfony_password@database:5432/symfony?serverVersion=16&charset=utf8"

# Symfony
MESSENGER_TRANSPORT_DSN=doctrine://default?auto_setup=0

# Timezone
TZ=Europe/Paris
EOF

# ============================================================
# 4. .env.test
# ============================================================

cat > .env.test <<'EOF'
APP_ENV=test
APP_SECRET=test_secret

DATABASE_URL="postgresql://symfony:symfony_password@database:5432/symfony_test?serverVersion=16&charset=utf8"

MESSENGER_TRANSPORT_DSN=sync://
EOF

# ============================================================
# 5. composer.json
# ============================================================

cat > composer.json <<'EOF'
{
    "type": "project",
    "license": "proprietary",
    "minimum-stability": "stable",
    "prefer-stable": true,

    "require": {
        "php": ">=8.2",
        "ext-ctype": "*",
        "ext-iconv": "*",
        "symfony/console": "6.4.*",
        "symfony/dotenv": "6.4.*",
        "symfony/flex": "^2",
        "symfony/framework-bundle": "6.4.*",
        "symfony/runtime": "6.4.*",
        "symfony/yaml": "6.4.*",
        "symfony/twig-bundle": "6.4.*",
        "symfony/asset": "6.4.*",
        "symfony/orm-pack": "*",
        "symfony/security-bundle": "6.4.*",
        "symfony/form": "6.4.*",
        "symfony/validator": "6.4.*",
        "symfony/monolog-bundle": "^3.0",
        "twig/extra-bundle": "^3.0",
        "twig/twig": "^3.0"
    },

    "require-dev": {
        "symfony/maker-bundle": "^1.50",
        "symfony/test-pack": "*",
        "phpunit/phpunit": "^9.6"
    },

    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    },

    "autoload-dev": {
        "psr-4": {
            "App\\Tests\\": "tests/"
        }
    },

    "scripts": {
        "auto-scripts": {
            "cache:clear": "symfony-cmd"
        },
        "post-install-cmd": [
            "@auto-scripts"
        ],
        "post-update-cmd": [
            "@auto-scripts"
        ],
        "test": "php bin/phpunit"
    },

    "extra": {
        "symfony": {
            "allow-contrib": false,
            "require": "6.4.*"
        }
    }
}
EOF

# ============================================================
# 6. phpunit.xml.dist
# ============================================================

cat > phpunit.xml.dist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>

<phpunit
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/9.6/phpunit.xsd"
    bootstrap="tests/bootstrap.php"
    colors="true"
    failOnRisky="true"
    failOnWarning="true"
>

    <php>
        <server name="APP_ENV" value="test" force="true"/>
        <server name="SHELL_VERBOSITY" value="-1"/>

        <env name="APP_ENV" value="test"/>
    </php>

    <testsuites>
        <testsuite name="Application Test Suite">
            <directory>tests</directory>
        </testsuite>
    </testsuites>

    <coverage>
        <include>
            <directory suffix=".php">src</directory>
        </include>
    </coverage>

</phpunit>
EOF

# ============================================================
# 7. tests/bootstrap.php
# ============================================================

mkdir -p tests

cat > tests/bootstrap.php <<'EOF'
<?php

use Symfony\Component\Dotenv\Dotenv;

require dirname(__DIR__) . '/vendor/autoload.php';

if (file_exists(dirname(__DIR__) . '/.env.test')) {
    (new Dotenv())->bootEnv(dirname(__DIR__) . '/.env.test');
}
EOF

# ============================================================
# 8. config/bundles.php
# ============================================================

mkdir -p config

cat > config/bundles.php <<'EOF'
<?php

return [
    Symfony\Bundle\FrameworkBundle\FrameworkBundle::class => ['all' => true],
    Symfony\Bundle\TwigBundle\TwigBundle::class => ['all' => true],
    Symfony\Bundle\SecurityBundle\SecurityBundle::class => ['all' => true],
    Doctrine\Bundle\DoctrineBundle\DoctrineBundle::class => ['all' => true],
    Symfony\Bundle\MonologBundle\MonologBundle::class => ['all' => true],
];
EOF

# ============================================================
# 9. config/services.yaml
# ============================================================

cat > config/services.yaml <<'EOF'
parameters:

services:

    _defaults:
        autowire: true
        autoconfigure: true

    App\:
        resource: '../src/'
        exclude:
            - '../src/DependencyInjection/'
            - '../src/Entity/'
            - '../src/Kernel.php'
EOF

# ============================================================
# 10. config/routes.yaml
# ============================================================

cat > config/routes.yaml <<'EOF'
controllers:
    resource:
        path: ../src/Controller/
        namespace: App\Controller
    type: attribute
EOF

# ============================================================
# 11. config/packages/framework.yaml
# ============================================================

mkdir -p config/packages

cat > config/packages/framework.yaml <<'EOF'
framework:

    secret: '%env(APP_SECRET)%'

    csrf_protection: true

    http_method_override: false

    handle_all_throwables: true

    php_errors:
        log: true

    router:
        utf8: true

    session:
        handler_id: null
        cookie_secure: auto
        cookie_samesite: lax

    assets:
        version: '1.0'
EOF

# ============================================================
# 12. config/packages/doctrine.yaml
# ============================================================

cat > config/packages/doctrine.yaml <<'EOF'
doctrine:

    dbal:
        url: '%env(resolve:DATABASE_URL)%'

        # Important pour éviter les problèmes de version
        # lors de la connexion à PostgreSQL.
        server_version: '16'

    orm:
        auto_generate_proxy_classes: true

        enable_lazy_ghost_objects: true

        auto_mapping: true

        mappings:
            App:
                type: attribute
                is_bundle: false
                dir: '%kernel.project_dir%/src/Entity'
                prefix: 'App\Entity'
                alias: App
EOF

# ============================================================
# 13. config/packages/twig.yaml
# ============================================================

cat > config/packages/twig.yaml <<'EOF'
twig:

    default_path: '%kernel.project_dir%/templates'

    globals:
        app_name: 'Symfony Blog'
EOF

# ============================================================
# 14. config/packages/monolog.yaml
# ============================================================

cat > config/packages/monolog.yaml <<'EOF'
monolog:

    channels:
        - deprecation

    handlers:

        main:
            type: fingers_crossed
            action_level: error
            handler: nested
            excluded_http_codes: [404, 405]

        nested:
            type: stream
            path: '%kernel.logs_dir%/%kernel.environment%.log'
            level: debug

        console:
            type: console
            process_psr_3_messages: false
            channels:
                - '!event'
                - '!doctrine'

        deprecation:
            type: stream
            channels: [deprecation]
            path: '%kernel.logs_dir%/%kernel.environment%.deprecations.log'
EOF

# ============================================================
# 15. config/packages/security.yaml
# ============================================================

cat > config/packages/security.yaml <<'EOF'
security:

    password_hashers:
        Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface:
            algorithm: auto

    providers:
        users_in_memory:
            memory: ~

    firewalls:

        dev:
            pattern: ^/(_(profiler|wdt)|css|images|js)/
            security: false

        main:
            lazy: true
            provider: users_in_memory

    access_control:
        # Les règles d'accès seront complétées
        # lorsque l'authentification admin sera configurée.
EOF

# ============================================================
# 16. config/packages/test/framework.yaml
# ============================================================

mkdir -p config/packages/test

cat > config/packages/test/framework.yaml <<'EOF'
framework:

    test: true

    session:
        storage_factory_id: session.storage.factory.mock_file
EOF

# ============================================================
# 17. README.md
# ============================================================

cat > README.md <<'EOF'
# Symfony Blog - Projet DevOps

Projet Symfony Blog utilisé comme support pour une démarche DevOps.

## Architecture cible

Le projet sera progressivement complété avec :

- Symfony
- PostgreSQL
- Docker
- Docker Compose
- GitHub Actions
- Kubernetes
- Prometheus
- Grafana
- Tests automatisés
- Tests de charge
- SLI / SLO
- Alerting
- Scalabilité
- Déploiement automatisé

## Organisation

```text
src/              Application Symfony
tests/            Tests automatisés
docker/           Configuration Docker
k8s/              Kubernetes
monitoring/       Prometheus / Grafana
.github/          CI/CD
scripts/          Scripts d'automatisation
docs/             Documentation

DevOps

Le cycle cible est :

User Story
    ↓
Développement
    ↓
Tests
    ↓
Git
    ↓
CI
    ↓
Build Docker
    ↓
Registry
    ↓
Kubernetes
    ↓
Smoke Tests
    ↓
Monitoring
    ↓
SLI / SLO
    ↓
Alerting

Important

Les composants DevOps seront ajoutés progressivement.
EOF
============================================================
18. Résumé
============================================================

echo
echo "=============================================="
echo " Partie 2 terminée"
echo "=============================================="

echo
echo "Fichiers de configuration créés dans :"
echo "$PROJECT_DIR"

echo
echo "Aucune installation effectuée."
echo "Aucun conteneur démarré."
echo "Aucun cluster Kubernetes créé."

echo
echo "Pour voir les fichiers :"
echo
echo "cd $PROJECT_DIR"
echo "tree -a -I .git"

echo
echo "=============================================="

:::

### Ce que fait cette partie

On a maintenant la séparation :

```text
01 → création de l'arborescence
02 → configuration Symfony
03 → Docker
04 → tests
05 → CI/CD
06 → Kubernetes
07 → production / scalabilité
08 → monitoring / SLI / SLO
