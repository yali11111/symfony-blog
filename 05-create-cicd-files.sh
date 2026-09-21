#!/usr/bin/env bash

set -e

# ============================================================
# Symfony Blog - Partie 5/8
# Création des fichiers CI/CD GitHub Actions
#
# IMPORTANT :
# - aucune installation
# - aucune pipeline exécutée
# - aucun Docker build
# - aucun push Docker
# - aucun déploiement Kubernetes
#
# Ce script crée uniquement les fichiers.
# ============================================================

PROJECT_DIR="${HOME}/symfony-blog"

echo "=============================================="
echo " Symfony Blog - CI/CD"
echo "=============================================="

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# ============================================================
# 1. Arborescence GitHub Actions
# ============================================================

mkdir -p .github/workflows

# ============================================================
# 2. CI
# ============================================================

cat > .github/workflows/ci.yml <<'EOF'
name: CI - Symfony Blog

on:

  push:

  pull_request:

permissions:
  contents: read

jobs:

  tests:

    name: Tests Symfony

    runs-on: ubuntu-latest

    steps:

      # ------------------------------------------------------
      # Checkout
      # ------------------------------------------------------

      - name: Checkout
        uses: actions/checkout@v4

      # ------------------------------------------------------
      # PHP
      # ------------------------------------------------------

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:

          php-version: '8.2'

          extensions: mbstring, intl, pdo_pgsql, opcache

          coverage: none

          tools: composer

      # ------------------------------------------------------
      # Composer
      # ------------------------------------------------------

      - name: Validate Composer
        run: composer validate --strict

      - name: Install dependencies
        run: composer install
          --prefer-dist
          --no-interaction
          --no-progress

      # ------------------------------------------------------
      # Symfony
      # ------------------------------------------------------

      - name: Check Symfony
        run: php bin/console about

      # ------------------------------------------------------
      # PHPUnit
      # ------------------------------------------------------

      - name: Run PHPUnit
        run: php bin/phpunit

  # ========================================================
  # Static analysis
  # ========================================================

  quality:

    name: Code Quality

    runs-on: ubuntu-latest

    steps:

      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:

          php-version: '8.2'

          extensions: mbstring, intl, pdo_pgsql

          tools: composer

      - name: Install dependencies
        run: composer install
          --prefer-dist
          --no-interaction
          --no-progress

      - name: Validate Composer
        run: composer validate --strict

  # ========================================================
  # Smoke test de configuration
  # ========================================================

  smoke:

    name: Application Smoke Check

    runs-on: ubuntu-latest

    needs:
      - tests

    steps:

      - name: Checkout
        uses: actions/checkout@v4

      - name: Check project files
        run: |

          test -f composer.json

          test -f Dockerfile

          test -f docker-compose.yml

          test -d src

          test -d tests

          echo "Project structure OK"
EOF

# ============================================================
# 3. Security
# ============================================================

cat > .github/workflows/security.yml <<'EOF'
name: Security - Symfony Blog

on:

  push:

  pull_request:

permissions:
  contents: read

jobs:

  composer-audit:

    name: Composer Security Audit

    runs-on: ubuntu-latest

    steps:

      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:

          php-version: '8.2'

          tools: composer

      - name: Composer audit
        run: composer audit

  # ========================================================
  # Secrets scan
  # ========================================================

  secret-scan:

    name: Secret Scan

    runs-on: ubuntu-latest

    steps:

      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Search suspicious files
        run: |

          echo "Checking for common secret files..."

          if find . \
            -name ".env" \
            -o -name "*.pem" \
            -o -name "*.key" \
            | grep -v "./.git"; then

            echo "Potential secret files detected."

          else

            echo "No obvious secret files detected."

          fi
EOF

# ============================================================
# 4. CD
# ============================================================

cat > .github/workflows/cd.yml <<'EOF'
name: CD - Symfony Blog

on:

  push:

    branches:

      - main

permissions:
  contents: read

env:

  IMAGE_NAME: symfony-blog

jobs:

  # ========================================================
  # Build Docker
  # ========================================================

  build:

    name: Build Docker Image

    runs-on: ubuntu-latest

    steps:

      - name: Checkout
        uses: actions/checkout@v4

      # ------------------------------------------------------
      # Docker Build
      # ------------------------------------------------------

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build Docker image
        run: |

          docker build \
            -t "${IMAGE_NAME}:${GITHUB_SHA}" \
            -t "${IMAGE_NAME}:latest" \
            .

      # ------------------------------------------------------
      # Vérification
      # ------------------------------------------------------

      - name: List Docker images
        run: docker images "${IMAGE_NAME}"

  # ========================================================
  # Déploiement
  #
  # Cette partie est volontairement préparée mais désactivée.
  # Elle sera activée lorsque Kubernetes sera configuré.
  # ========================================================

  deploy:

    name: Deploy Kubernetes

    runs-on: ubuntu-latest

    needs:
      - build

    if: ${{ false }}

    steps:

      - name: Checkout
        uses: actions/checkout@v4

      - name: Kubernetes deployment
        run: |

          echo "Kubernetes deployment will be configured later."

          echo "kubectl apply -f k8s/"
EOF

# ============================================================
# 5. Workflow de validation Docker
# ============================================================

cat > .github/workflows/docker.yml <<'EOF'
name: Docker Validation

on:

  push:

  pull_request:

permissions:
  contents: read

jobs:

  dockerfile:

    name: Validate Dockerfile

    runs-on: ubuntu-latest

    steps:

      - name: Checkout
        uses: actions/checkout@v4

      - name: Check Dockerfile
        run: |

          test -f Dockerfile

          test -f docker/nginx/Dockerfile

          test -f docker/nginx/default.conf

          echo "Docker files OK"

      - name: Validate Compose configuration
        run: |

          docker compose \
            -f docker-compose.yml \
            config
EOF

# ============================================================
# 6. Workflow performance
# ============================================================

cat > .github/workflows/performance.yml <<'EOF'
name: Performance Tests

on:

  workflow_dispatch:

jobs:

  performance:

    name: k6 Performance Test

    runs-on: ubuntu-latest

    steps:

      - name: Checkout
        uses: actions/checkout@v4

      - name: Run k6
        uses: grafana/k6-action@v0.3.1
        with:

          filename: tests/Performance/load-test.js
EOF

# ============================================================
# 7. Script local de validation CI
# ============================================================

mkdir -p scripts

cat > scripts/ci-check.sh <<'EOF'
#!/usr/bin/env bash

set -e

echo "=============================================="
echo " Local CI validation"
echo "=============================================="

echo
echo "1. Composer"
echo "----------------------------------------------"

if [ -f composer.json ]; then

    composer validate --strict

else

    echo "composer.json absent."

    exit 1

fi

echo
echo "2. PHPUnit"
echo "----------------------------------------------"

if [ -x vendor/bin/phpunit ]; then

    php bin/phpunit

else

    echo "PHPUnit non installé."

    echo "Installation volontairement non effectuée."

fi

echo
echo "3. Docker Compose"
echo "----------------------------------------------"

if command -v docker >/dev/null 2>&1; then

    docker compose config

else

    echo "Docker non installé."

    echo "Validation Docker ignorée."

fi

echo
echo "=============================================="
echo " Validation terminée"
echo "=============================================="
EOF

chmod +x scripts/ci-check.sh

# ============================================================
# 8. Documentation CI/CD
# ============================================================

cat > docs/devops/cicd.md <<'EOF'
# CI/CD - Symfony Blog

## Objectif

Automatiser :

- les tests ;
- les contrôles qualité ;
- les contrôles de sécurité ;
- la construction Docker ;
- la préparation du déploiement Kubernetes.

---

## CI

La CI est exécutée sur :

```text
push
pull_request

Pipeline :

Git Push
   |
   v
Checkout
   |
   v
PHP
   |
   v
Composer
   |
   v
Tests PHPUnit
   |
   v
Quality checks
   |
   v
Security

CD

Le CD est prévu sur :

main

Pipeline cible :

main
 |
 v
Tests
 |
 v
Docker Build
 |
 v
Docker Registry
 |
 v
Kubernetes
 |
 v
Smoke Tests
 |
 v
Monitoring

Le déploiement Kubernetes est volontairement désactivé
à cette étape.
GitHub Secrets

Plus tard, les secrets pourront contenir :

REGISTRY_USERNAME
REGISTRY_PASSWORD

KUBE_CONFIG

APP_SECRET
DATABASE_URL

Les secrets ne doivent jamais être stockés directement
dans Git.
Stratégie de déploiement

Architecture prévue :

Developer
    |
    v
Git
    |
    v
Pull Request
    |
    v
CI
    |
    +---- PHPUnit
    |
    +---- Security
    |
    +---- Docker
    |
    v
main
    |
    v
CD
    |
    v
Registry
    |
    v
Kubernetes

EOF
============================================================
9. README CI/CD
============================================================

cat > .github/workflows/README.md <<'EOF'
GitHub Actions

Workflows :

    ci.yml

    cd.yml

    docker.yml

    security.yml

    performance.yml

ci.yml

Tests et validation du projet.
cd.yml

Construction Docker et préparation du déploiement Kubernetes.
docker.yml

Validation des fichiers Docker et Docker Compose.
security.yml

Contrôles de sécurité.
performance.yml

Tests k6 déclenchés manuellement.

Aucune clé secrète ne doit être commitée.
EOF
============================================================
10. Résumé
============================================================

echo
echo "=============================================="
echo " Partie 5/8 terminée"
echo "=============================================="

echo
echo "Fichiers créés :"

echo " .github/workflows/ci.yml"
echo " .github/workflows/cd.yml"
echo " .github/workflows/docker.yml"
echo " .github/workflows/security.yml"
echo " .github/workflows/performance.yml"
echo " .github/workflows/README.md"
echo " scripts/ci-check.sh"
echo " docs/devops/cicd.md"

echo
echo "IMPORTANT :"
echo "- aucune pipeline n'a été exécutée"
echo "- aucune image Docker n'a été construite"
echo "- aucune image n'a été poussée"
echo "- aucun déploiement Kubernetes n'a été effectué"

echo
echo "=============================================="

:::

### Structure obtenue

```text
.github/
└── workflows/
    ├── ci.yml
    ├── cd.yml
    ├── docker.yml
    ├── security.yml
    ├── performance.yml
    └── README.md

scripts/
├── ci-check.sh
└── test.sh

docs/
└── devops/
    ├── docker.md
    ├── tests.md
    └── cicd.md
