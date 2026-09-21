#!/bin/bash

set -e

echo "=========================================="
echo " Partie 17 - Symfony + MySQL"
echo "=========================================="

echo "[1/3] Vérification de .env..."

if [ ! -f ".env" ]; then
    echo "❌ .env introuvable."
    exit 1
fi

echo "✅ .env trouvé."

echo "[2/3] Création du fichier .env.local..."

cat > .env.local <<'EOF'
APP_ENV=dev
APP_DEBUG=1

DATABASE_URL="mysql://symfony:symfony@database:3306/symfony?serverVersion=8.0"
EOF

echo "✅ .env.local créé."

echo "[3/3] Création d'un exemple de configuration..."

cat > .env.local.example <<'EOF'
APP_ENV=dev
APP_DEBUG=1

DATABASE_URL="mysql://symfony:symfony@database:3306/symfony?serverVersion=8.0"
EOF

echo "✅ .env.local.example créé."

echo ""
echo "=========================================="
echo " Partie 17 terminée"
echo "=========================================="

echo ""
echo "Configuration :"
echo "Symfony → database:3306 → MySQL"
echo ""
echo "⚠️ .env.local contient des identifiants locaux."
echo "⚠️ Ne pas versionner .env.local."
echo "⚠️ Aucun conteneur n'a été démarré."
echo "⚠️ Aucun cluster Kubernetes n'a été créé."
