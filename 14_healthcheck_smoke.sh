#!/bin/bash

set -e

echo "=========================================="
echo " Partie 14 - Health Checks & Smoke Tests"
echo "=========================================="

if [ ! -f "composer.json" ]; then
    echo "❌ composer.json introuvable."
    echo "Lance ce script à la racine du projet Symfony."
    exit 1
fi

echo "[1/4] Création du répertoire des scripts..."

mkdir -p scripts

echo "✅ Répertoire scripts créé."

echo "[2/4] Création du smoke test..."

cat > scripts/smoke-test.sh <<'EOF'
#!/bin/bash

set -e

BASE_URL="${BASE_URL:-http://localhost:8080}"

echo "=========================================="
echo " Smoke Test - Symfony Blog"
echo "=========================================="
echo ""
echo "URL testée : $BASE_URL"
echo ""

check_endpoint() {

    ENDPOINT="$1"

    echo "Test : $ENDPOINT"

    HTTP_CODE=$(curl \
        --silent \
        --output /dev/null \
        --write-out "%{http_code}" \
        --max-time 10 \
        "$BASE_URL$ENDPOINT")

    if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
        echo "✅ $ENDPOINT → HTTP $HTTP_CODE"
    else
        echo "❌ $ENDPOINT → HTTP $HTTP_CODE"
        exit 1
    fi
}

check_endpoint "/"

echo ""
echo "=========================================="
echo " Smoke Test réussi"
echo "=========================================="
EOF

chmod +x scripts/smoke-test.sh

echo "✅ smoke-test.sh créé."

echo "[3/4] Création du health check..."

cat > scripts/health-check.sh <<'EOF'
#!/bin/bash

set -e

BASE_URL="${BASE_URL:-http://localhost:8080}"

echo "=========================================="
echo " Health Check - Symfony Blog"
echo "=========================================="

HTTP_CODE=$(curl \
    --silent \
    --output /dev/null \
    --write-out "%{http_code}" \
    --max-time 5 \
    "$BASE_URL/")

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
    echo "STATUS=UP"
    echo "HTTP=$HTTP_CODE"
    exit 0
fi

echo "STATUS=DOWN"
echo "HTTP=$HTTP_CODE"

exit 1
EOF

chmod +x scripts/health-check.sh

echo "✅ health-check.sh créé."

echo "[4/4] Création du script de vérification..."

cat > scripts/check-application.sh <<'EOF'
#!/bin/bash

set -e

echo "=========================================="
echo " Vérification Symfony Blog"
echo "=========================================="

BASE_URL="${BASE_URL:-http://localhost:8080}"

echo ""
echo "1. Vérification de l'application..."
echo ""

if curl --fail --silent --max-time 10 "$BASE_URL/" > /dev/null; then
    echo "✅ Application accessible"
else
    echo "❌ Application inaccessible"
    exit 1
fi

echo ""
echo "2. Vérification du temps de réponse..."
echo ""

TIME=$(curl \
    --silent \
    --output /dev/null \
    --write-out "%{time_total}" \
    --max-time 10 \
    "$BASE_URL/")

echo "Temps de réponse : ${TIME}s"

echo ""
echo "3. Vérification terminée."
echo ""
echo "STATUS=OK"
EOF

chmod +x scripts/check-application.sh

echo "✅ check-application.sh créé."

echo ""
echo "=========================================="
echo " Partie 14 terminée"
echo "=========================================="
echo ""
echo "Scripts créés :"
echo ""
echo "scripts/"
echo "├── smoke-test.sh"
echo "├── health-check.sh"
echo "└── check-application.sh"
echo ""
echo "URL par défaut :"
echo "http://localhost:8080"
echo ""
echo "⚠️ Aucun conteneur n'est démarré."
echo "⚠️ Aucun cluster Kubernetes n'est créé."
echo "⚠️ Les tests seront exécutés lorsque l'application sera disponible."
