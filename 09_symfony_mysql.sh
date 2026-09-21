#!/bin/bash

set -e

echo "=========================================="
echo " Partie 9 - Symfony + MySQL"
echo "=========================================="

# Vérification
if [ ! -f "composer.json" ]; then
    echo "⚠️ composer.json n'est pas présent."
    echo "Place ce script à la racine du projet Symfony."
fi

echo "[1/3] Configuration de l'environnement Symfony..."

cat > .env <<'EOF'
APP_ENV=dev
APP_SECRET=change_me_in_production

DATABASE_URL="mysql://symfony:symfony_password@database:3306/symfony?serverVersion=8.0&charset=utf8mb4"

###> symfony/framework-bundle ###
APP_DEBUG=1
###< symfony/framework-bundle ###
EOF


echo "[2/3] Configuration de l'environnement de test..."

cat > .env.test <<'EOF'
APP_ENV=test
APP_SECRET=test_secret

DATABASE_URL="mysql://symfony:symfony_password@database:3306/symfony_test?serverVersion=8.0&charset=utf8mb4"

APP_DEBUG=1
EOF


echo "[3/3] Création d'un exemple de configuration locale..."

cat > .env.local.example <<'EOF'
# Copie ce fichier vers .env.local
# Ne jamais mettre les vrais secrets dans Git.

APP_ENV=dev

APP_SECRET=change_me

DATABASE_URL="mysql://symfony:symfony_password@database:3306/symfony?serverVersion=8.0&charset=utf8mb4"
EOF


echo ""
echo "=========================================="
echo " Partie 9 terminée"
echo "=========================================="
echo ""
echo "Configuration créée :"
echo "  .env"
echo "  .env.test"
echo "  .env.local.example"
echo ""
echo "⚠️ Aucun conteneur n'a été lancé."
echo "⚠️ Aucun cluster Kubernetes n'a été créé."
echo ""
echo "Étape suivante : tests de la configuration Symfony/MySQL."
