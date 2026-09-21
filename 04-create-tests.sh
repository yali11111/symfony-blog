#!/usr/bin/env bash

set -e

# ============================================================
# Symfony Blog - Partie 4/8
# Création de l'infrastructure de tests
#
# IMPORTANT :
# - aucune installation
# - aucun test exécuté
# - aucun conteneur lancé
# - aucun cluster Kubernetes
#
# Ce script crée uniquement les fichiers.
# ============================================================

PROJECT_DIR="${HOME}/symfony-blog"

echo "=============================================="
echo " Symfony Blog - Tests"
echo "=============================================="

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# ============================================================
# 1. Arborescence des tests
# ============================================================

mkdir -p \
    tests/Unit \
    tests/Functional \
    tests/Integration \
    tests/Smoke \
    tests/Performance \
    tests/Fixtures

# ============================================================
# 2. PHPUnit
# ============================================================

cat > phpunit.xml.dist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>

<phpunit
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/10.5/phpunit.xsd"
    bootstrap="tests/bootstrap.php"
    colors="true"
    failOnRisky="true"
    failOnWarning="true"
>

    <php>
        <server name="APP_ENV" value="test" force="true"/>
        <server name="SHELL_VERBOSITY" value="-1"/>
    </php>

    <testsuites>

        <testsuite name="Unit">
            <directory>tests/Unit</directory>
        </testsuite>

        <testsuite name="Functional">
            <directory>tests/Functional</directory>
        </testsuite>

        <testsuite name="Integration">
            <directory>tests/Integration</directory>
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
# 3. Bootstrap PHPUnit
# ============================================================

cat > tests/bootstrap.php <<'EOF'
<?php

declare(strict_types=1);

use Symfony\Component\Dotenv\Dotenv;

require dirname(__DIR__) . '/vendor/autoload.php';

if (class_exists(Dotenv::class)) {
    $dotenv = new Dotenv();

    if (file_exists(dirname(__DIR__) . '/.env.test')) {
        $dotenv->loadEnv(dirname(__DIR__) . '/.env.test');
    }
}
EOF

# ============================================================
# 4. Exemple de test unitaire
# ============================================================

cat > tests/Unit/ExampleTest.php <<'EOF'
<?php

declare(strict_types=1);

namespace App\Tests\Unit;

use PHPUnit\Framework\TestCase;

final class ExampleTest extends TestCase
{
    public function testBasicAssertion(): void
    {
        self::assertTrue(true);
    }
}
EOF

# ============================================================
# 5. Test fonctionnel HTTP
# ============================================================

cat > tests/Functional/HomepageTest.php <<'EOF'
<?php

declare(strict_types=1);

namespace App\Tests\Functional;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class HomepageTest extends WebTestCase
{
    public function testHomepageIsAccessible(): void
    {
        $client = static::createClient();

        $client->request('GET', '/');

        self::assertResponseIsSuccessful();
    }
}
EOF

# ============================================================
# 6. Test fonctionnel du blog
# ============================================================

cat > tests/Functional/BlogTest.php <<'EOF'
<?php

declare(strict_types=1);

namespace App\Tests\Functional;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

final class BlogTest extends WebTestCase
{
    public function testBlogPageIsAccessible(): void
    {
        $client = static::createClient();

        $client->request('GET', '/blog');

        self::assertResponseIsSuccessful();
    }
}
EOF

# ============================================================
# 7. Test d'intégration
# ============================================================

cat > tests/Integration/DatabaseConnectionTest.php <<'EOF'
<?php

declare(strict_types=1);

namespace App\Tests\Integration;

use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

final class DatabaseConnectionTest extends KernelTestCase
{
    public function testKernelCanBoot(): void
    {
        self::bootKernel();

        self::assertNotNull(self::$kernel);
    }
}
EOF

# ============================================================
# 8. Smoke test
# ============================================================

cat > tests/Smoke/smoke.sh <<'EOF'
#!/usr/bin/env bash

set -e

BASE_URL="${BASE_URL:-http://localhost:8080}"

echo "=============================================="
echo " Symfony Blog - Smoke Tests"
echo "=============================================="

check_url() {

    local URL="$1"

    echo "Test : ${URL}"

    HTTP_CODE=$(curl \
        --silent \
        --output /dev/null \
        --write-out "%{http_code}" \
        "$URL")

    if [[ "$HTTP_CODE" =~ ^2|^3 ]]; then

        echo "OK - HTTP ${HTTP_CODE}"

    else

        echo "ERREUR - HTTP ${HTTP_CODE}"

        exit 1
    fi
}

check_url "${BASE_URL}/"

check_url "${BASE_URL}/health"

echo
echo "Smoke tests OK."
EOF

chmod +x tests/Smoke/smoke.sh

# ============================================================
# 9. Smoke test Kubernetes
# ============================================================

cat > tests/Smoke/kubernetes-smoke.sh <<'EOF'
#!/usr/bin/env bash

set -e

NAMESPACE="${K8S_NAMESPACE:-symfony-blog}"
SERVICE="${K8S_SERVICE:-symfony-blog}"

echo "=============================================="
echo " Kubernetes Smoke Test"
echo "=============================================="

echo "Namespace : ${NAMESPACE}"
echo "Service   : ${SERVICE}"

kubectl get pods -n "${NAMESPACE}"

kubectl get service "${SERVICE}" -n "${NAMESPACE}"

echo
echo "Vérification terminée."
EOF

chmod +x tests/Smoke/kubernetes-smoke.sh

# ============================================================
# 10. Test de charge k6
# ============================================================

cat > tests/Performance/load-test.js <<'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {

    vus: 10,

    duration: '30s',

    thresholds: {

        http_req_failed: [
            'rate<0.01'
        ],

        http_req_duration: [
            'p(95)<500'
        ]

    }

};

export default function () {

    const response = http.get(
        __ENV.BASE_URL || 'http://localhost:8080/'
    );

    check(response, {

        'HTTP 200/300': (r) =>
            r.status >= 200 && r.status < 400,

    });

    sleep(1);
}
EOF

# ============================================================
# 11. Test de montée en charge
# ============================================================

cat > tests/Performance/stress-test.js <<'EOF'
import http from 'k6/http';
import { check } from 'k6';

export const options = {

    stages: [

        { duration: '30s', target: 10 },

        { duration: '30s', target: 25 },

        { duration: '30s', target: 50 },

        { duration: '30s', target: 100 },

        { duration: '30s', target: 0 }

    ],

    thresholds: {

        http_req_failed: [
            'rate<0.05'
        ]

    }

};

export default function () {

    const response = http.get(
        __ENV.BASE_URL || 'http://localhost:8080/'
    );

    check(response, {

        'status OK': (r) =>
            r.status >= 200 && r.status < 400,

    });
}
EOF

# ============================================================
# 12. Test de disponibilité
# ============================================================

cat > tests/Performance/availability-test.js <<'EOF'
import http from 'k6/http';

export const options = {

    vus: 1,

    duration: '5m',

    thresholds: {

        http_req_failed: [
            'rate<0.001'
        ]

    }

};

export default function () {

    http.get(
        __ENV.BASE_URL || 'http://localhost:8080/'
    );

}
EOF

# ============================================================
# 13. Script général de tests
# ============================================================

mkdir -p scripts

cat > scripts/test.sh <<'EOF'
#!/usr/bin/env bash

set -e

echo "=============================================="
echo " Symfony Blog - Test Suite"
echo "=============================================="

echo
echo "1. Tests PHPUnit"
echo "----------------------------------------------"

php bin/phpunit

echo
echo "2. Tests Smoke"
echo "----------------------------------------------"

./tests/Smoke/smoke.sh

echo
echo "=============================================="
echo " Tous les tests sont terminés."
echo "=============================================="
EOF

chmod +x scripts/test.sh

# ============================================================
# 14. Test de santé de l'application
# ============================================================

cat > tests/Smoke/healthcheck.sh <<'EOF'
#!/usr/bin/env bash

set -e

URL="${HEALTH_URL:-http://localhost:8080/health}"

echo "Health check : ${URL}"

HTTP_CODE=$(curl \
    --silent \
    --output /dev/null \
    --write-out "%{http_code}" \
    "$URL")

if [ "$HTTP_CODE" = "200" ]; then

    echo "Application disponible."

else

    echo "Application indisponible : HTTP ${HTTP_CODE}"

    exit 1
fi
EOF

chmod +x tests/Smoke/healthcheck.sh

# ============================================================
# 15. Documentation des tests
# ============================================================

cat > docs/devops/tests.md <<'EOF'
# Tests DevOps - Symfony Blog

## Tests unitaires

Répertoire :

```text
tests/Unit/

Objectif :

Tester la logique métier indépendamment de la base de données.
Tests fonctionnels

Répertoire :

tests/Functional/

Objectif :

Tester les parcours HTTP de l'application.

Exemples :

    accueil ;

    blog ;

    authentification ;

    administration ;

    recherche ;

    création d'article.

Tests d'intégration

Répertoire :

tests/Integration/

Objectif :

Tester l'interaction entre Symfony et ses dépendances.

Exemples :

    Doctrine ;

    PostgreSQL ;

    services Symfony.

Smoke tests

Répertoire :

tests/Smoke/

Objectif :

Vérifier rapidement qu'une version déployée fonctionne.

Exemples :

GET /
GET /health
GET /blog

Tests de performance

Répertoire :

tests/Performance/

Outil :

k6

Tests :

load-test.js
stress-test.js
availability-test.js

Métriques :

    temps de réponse ;

    p95 ;

    p99 ;

    taux d'erreur ;

    requêtes/seconde.

SLO de performance

Exemple :

p95 < 500 ms
taux d'erreur < 1 %

Ces valeurs sont des objectifs de projet et devront être ajustées
après les premières mesures réelles.
Chaîne de validation

Git Push
   |
   v
Tests unitaires
   |
   v
Tests fonctionnels
   |
   v
Tests intégration
   |
   v
Build Docker
   |
   v
Déploiement staging
   |
   v
Smoke tests
   |
   v
Tests de performance
   |
   v
Production

EOF
============================================================
16. Fichier .env.test.example
============================================================

cat > .env.test.example <<'EOF'
APP_ENV=test
APP_DEBUG=1

APP_SECRET=test-secret

DATABASE_URL="postgresql://symfony:symfony_password@database:5432/symfony_test?serverVersion=16&charset=utf8"
EOF
============================================================
17. Résumé
============================================================

echo
echo "=============================================="
echo " Partie 4/8 terminée"
echo "=============================================="

echo
echo "Arborescence créée :"

echo "tests/"
echo "├── Unit/"
echo "├── Functional/"
echo "├── Integration/"
echo "├── Smoke/"
echo "├── Performance/"
echo "└── Fixtures/"

echo
echo "Fichiers principaux :"

echo " phpunit.xml.dist"
echo " tests/bootstrap.php"
echo " tests/Smoke/smoke.sh"
echo " tests/Smoke/healthcheck.sh"
echo " tests/Smoke/kubernetes-smoke.sh"
echo " tests/Performance/load-test.js"
echo " tests/Performance/stress-test.js"
echo " tests/Performance/availability-test.js"
echo " scripts/test.sh"

echo
echo "IMPORTANT : aucun test n'a été exécuté."
echo "Aucune installation n'a été effectuée."
echo "Aucun conteneur n'a été lancé."

echo
echo "=============================================="

:::

### Arborescence obtenue

```text
symfony-blog/
├── tests/
│   ├── Unit/
│   │   └── ExampleTest.php
│   ├── Functional/
│   │   ├── HomepageTest.php
│   │   └── BlogTest.php
│   ├── Integration/
│   │   └── DatabaseConnectionTest.php
│   ├── Smoke/
│   │   ├── smoke.sh
│   │   ├── healthcheck.sh
│   │   └── kubernetes-smoke.sh
│   ├── Performance/
│   │   ├── load-test.js
│   │   ├── stress-test.js
│   │   └── availability-test.js
│   └── Fixtures/
│
├── scripts/
│   └── test.sh
│
├── phpunit.xml.dist
└── .env.test.example
