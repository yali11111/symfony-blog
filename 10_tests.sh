#!/bin/bash

set -e

echo "=========================================="
echo " Partie 10 - Tests automatisés Symfony"
echo "=========================================="

echo "[1/5] Vérification du projet..."

if [ ! -f "composer.json" ]; then
    echo "❌ composer.json introuvable."
    echo "Lance ce script à la racine du projet Symfony."
    exit 1
fi

echo "✅ Projet Symfony détecté."

echo "[2/5] Création des répertoires de tests..."

mkdir -p tests/Unit
mkdir -p tests/Functional
mkdir -p tests/Integration
mkdir -p tests/Performance

echo "✅ Répertoires créés."

echo "[3/5] Vérification de PHPUnit..."

if grep -q '"phpunit/phpunit"' composer.json; then
    echo "✅ PHPUnit est déjà présent dans composer.json."
else
    echo "⚠️ PHPUnit n'est pas encore déclaré."
    echo "Ajout de PHPUnit..."
    composer require --dev phpunit/phpunit
fi

echo "[4/5] Création de phpunit.xml.dist..."

cat > phpunit.xml.dist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>

<phpunit
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/10.5/phpunit.xsd"
    bootstrap="tests/bootstrap.php"
    colors="true"
>

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

        <testsuite name="Performance">
            <directory>tests/Performance</directory>
        </testsuite>

    </testsuites>

    <source>
        <include>
            <directory>src</directory>
        </include>
    </source>

</phpunit>
EOF

echo "✅ phpunit.xml.dist créé."

echo "[5/5] Création du bootstrap de tests..."

cat > tests/bootstrap.php <<'EOF'
<?php

use Symfony\Component\Dotenv\Dotenv;

require dirname(__DIR__) . '/vendor/autoload.php';

if (file_exists(dirname(__DIR__) . '/.env')) {
    (new Dotenv())->bootEnv(dirname(__DIR__) . '/.env');
}
EOF

echo "✅ tests/bootstrap.php créé."

echo ""
echo "=========================================="
echo " Partie 10 terminée"
echo "=========================================="
echo ""
echo "Structure des tests :"
echo ""
echo "tests/"
echo "├── Unit/"
echo "├── Functional/"
echo "├── Integration/"
echo "└── Performance/"
echo ""
echo "Configuration :"
echo "└── phpunit.xml.dist"
echo ""
echo "Bootstrap :"
echo "└── tests/bootstrap.php"
echo ""
echo "⚠️ Les tests ne sont pas exécutés automatiquement"
echo "par cette partie."
echo ""
echo "Prochaine étape : premiers tests Symfony."
