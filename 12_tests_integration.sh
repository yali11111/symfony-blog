#!/bin/bash

set -e

echo "=========================================="
echo " Partie 12 - Tests d'intégration"
echo " Symfony + Doctrine + MySQL"
echo "=========================================="

if [ ! -f "composer.json" ]; then
    echo "❌ composer.json introuvable."
    echo "Lance ce script à la racine du projet Symfony."
    exit 1
fi

echo "[1/4] Création du répertoire Integration..."

mkdir -p tests/Integration

echo "✅ Répertoire créé."

echo "[2/4] Création du test de connexion Doctrine..."

cat > tests/Integration/DatabaseConnectionTest.php <<'EOF'
<?php

namespace App\Tests\Integration;

use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

class DatabaseConnectionTest extends KernelTestCase
{
    public function testDatabaseConnection(): void
    {
        self::bootKernel();

        $container = static::getContainer();

        $entityManager = $container->get(EntityManagerInterface::class);

        $connection = $entityManager->getConnection();

        $this->assertTrue(
            $connection->isConnected() || $connection->connect()
        );
    }
}
EOF

echo "✅ DatabaseConnectionTest.php créé."

echo "[3/4] Création du test Doctrine..."

cat > tests/Integration/DoctrineTest.php <<'EOF'
<?php

namespace App\Tests\Integration;

use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

class DoctrineTest extends KernelTestCase
{
    public function testDoctrineIsAvailable(): void
    {
        self::bootKernel();

        $container = static::getContainer();

        $entityManager = $container->get(EntityManagerInterface::class);

        $this->assertInstanceOf(
            EntityManagerInterface::class,
            $entityManager
        );
    }
}
EOF

echo "✅ DoctrineTest.php créé."

echo "[4/4] Création d'un test de requête SQL..."

cat > tests/Integration/DatabaseQueryTest.php <<'EOF'
<?php

namespace App\Tests\Integration;

use Doctrine\DBAL\Connection;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

class DatabaseQueryTest extends KernelTestCase
{
    public function testDatabaseCanExecuteQuery(): void
    {
        self::bootKernel();

        $container = static::getContainer();

        $connection = $container->get(Connection::class);

        $result = $connection->fetchOne('SELECT 1');

        $this->assertSame(1, (int) $result);
    }
}
EOF

echo "✅ DatabaseQueryTest.php créé."

echo ""
echo "=========================================="
echo " Partie 12 terminée"
echo "=========================================="
echo ""
echo "Tests créés :"
echo ""
echo "tests/Integration/"
echo "├── DatabaseConnectionTest.php"
echo "├── DoctrineTest.php"
echo "└── DatabaseQueryTest.php"
echo ""
echo "Ces tests nécessitent une base MySQL accessible."
echo ""
echo "Exécution ultérieure :"
echo ""
echo "php bin/phpunit tests/Integration"
echo ""
echo "⚠️ Aucun conteneur n'a été démarré."
echo "⚠️ Aucun cluster Kubernetes n'a été créé."
