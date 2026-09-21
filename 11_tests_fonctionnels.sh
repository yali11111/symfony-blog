#!/bin/bash

set -e

echo "=========================================="
echo " Partie 11 - Tests fonctionnels"
echo "=========================================="

if [ ! -f "composer.json" ]; then
    echo "❌ composer.json introuvable."
    echo "Lance ce script à la racine du projet Symfony."
    exit 1
fi

echo "[1/4] Vérification du répertoire tests..."

mkdir -p tests/Functional

echo "[2/4] Création du test de fonctionnement général..."

cat > tests/Functional/BlogControllerTest.php <<'EOF'
<?php

namespace App\Tests\Functional;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

class BlogControllerTest extends WebTestCase
{
    public function testApplicationIsAccessible(): void
    {
        $client = static::createClient();

        /*
         * Remplace '/' par une route réellement présente
         * dans le projet si nécessaire.
         */
        $client->request('GET', '/');

        $this->assertResponseIsSuccessful();
    }
}
EOF

echo "✅ BlogControllerTest.php créé."

echo "[3/4] Création du test de page blog..."

cat > tests/Functional/BlogPageTest.php <<'EOF'
<?php

namespace App\Tests\Functional;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

class BlogPageTest extends WebTestCase
{
    public function testBlogPage(): void
    {
        $client = static::createClient();

        /*
         * Adapter cette URL à la route réelle du projet.
         * Exemple possible : /blog
         */
        $client->request('GET', '/blog');

        /*
         * Ce test sera activé une fois que la route
         * /blog existe dans l'application.
         */
        $this->assertResponseStatusCodeSame(200);
    }
}
EOF

echo "✅ BlogPageTest.php créé."

echo "[4/4] Création d'un test de sécurité de base..."

cat > tests/Functional/SecurityTest.php <<'EOF'
<?php

namespace App\Tests\Functional;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

class SecurityTest extends WebTestCase
{
    public function testPublicPageDoesNotReturnServerError(): void
    {
        $client = static::createClient();

        $client->request('GET', '/');

        $this->assertResponseStatusCodeSame(200);
    }
}
EOF

echo "✅ SecurityTest.php créé."

echo ""
echo "=========================================="
echo " Partie 11 terminée"
echo "=========================================="
echo ""
echo "Tests créés :"
echo ""
echo "tests/Functional/"
echo "├── BlogControllerTest.php"
echo "├── BlogPageTest.php"
echo "└── SecurityTest.php"
echo ""
echo "⚠️ IMPORTANT"
echo "Les routes / et /blog doivent correspondre"
echo "aux routes réellement présentes dans le projet."
echo ""
echo "Aucun conteneur n'a été démarré."
echo "Aucun cluster Kubernetes n'a été créé."
