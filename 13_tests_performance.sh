#!/bin/bash

set -e

echo "=========================================="
echo " Partie 13 - Tests de performance"
echo " k6 - Symfony Blog"
echo "=========================================="

if [ ! -f "composer.json" ]; then
    echo "❌ composer.json introuvable."
    echo "Lance ce script à la racine du projet Symfony."
    exit 1
fi

echo "[1/4] Création du répertoire Performance..."

mkdir -p tests/Performance

echo "✅ Répertoire créé."

echo "[2/4] Création du test de charge..."

cat > tests/Performance/load-test.js <<'EOF'
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
    stages: [
        { duration: '30s', target: 10 },
        { duration: '1m', target: 50 },
        { duration: '30s', target: 0 },
    ],

    thresholds: {
        http_req_failed: ['rate<0.01'],
        http_req_duration: ['p(95)<500', 'p(99)<1000'],
    },
};

export default function () {

    const response = http.get('http://localhost:8080/');

    check(response, {
        'HTTP 200': (r) => r.status === 200,
        'réponse < 500 ms': (r) => r.timings.duration < 500,
    });

    sleep(1);
}
EOF

echo "✅ load-test.js créé."

echo "[3/4] Création du test de montée en charge..."

cat > tests/Performance/stress-test.js <<'EOF'
import http from 'k6/http';
import { check } from 'k6';

export const options = {
    stages: [
        { duration: '30s', target: 10 },
        { duration: '30s', target: 50 },
        { duration: '30s', target: 100 },
        { duration: '30s', target: 200 },
        { duration: '30s', target: 0 },
    ],

    thresholds: {
        http_req_failed: ['rate<0.05'],
        http_req_duration: ['p(95)<1000'],
    },
};

export default function () {

    const response = http.get('http://localhost:8080/');

    check(response, {
        'application accessible': (r) => r.status >= 200 && r.status < 400,
    });
}
EOF

echo "✅ stress-test.js créé."

echo "[4/4] Création d'un README de performance..."

cat > tests/Performance/README.md <<'EOF'
# Tests de performance

Les tests utilisent k6.

## Test de charge

Fichier :

load-test.js

Scénario :

10 utilisateurs
        ↓
50 utilisateurs
        ↓
retour à 0

SLO :

- taux d'erreur < 1 %
- p95 < 500 ms
- p99 < 1 seconde

## Test de montée en charge

Fichier :

stress-test.js

Scénario :

10 → 50 → 100 → 200 utilisateurs

Objectif :

Identifier le niveau auquel les performances commencent à se dégrader.

## Exécution

Lorsque l'application est disponible :

k6 run tests/Performance/load-test.js

Puis :

k6 run tests/Performance/stress-test.js
EOF

echo "✅ README créé."

echo ""
echo "=========================================="
echo " Partie 13 terminée"
echo "=========================================="
echo ""
echo "Fichiers créés :"
echo ""
echo "tests/Performance/"
echo "├── load-test.js"
echo "├── stress-test.js"
echo "└── README.md"
echo ""
echo "SLO performance :"
echo "  - erreurs < 1 %"
echo "  - p95 < 500 ms"
echo "  - p99 < 1 seconde"
echo ""
echo "⚠️ k6 n'est pas installé par ce script."
echo "⚠️ Aucun test n'est exécuté."
echo "⚠️ Aucun conteneur ou cluster Kubernetes n'est lancé."
