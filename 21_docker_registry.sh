#!/bin/bash

set -e

echo "=========================================="
echo " Partie 23 - Kubernetes Namespace"
echo "=========================================="

mkdir -p k8s

cat > k8s/namespace.yaml <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: symfony-blog
  labels:
    app: symfony-blog
    environment: production
EOF

cat > k8s/README.md <<'EOF'
# Kubernetes - Symfony Blog

Les fichiers Kubernetes de ce répertoire décrivent
l'infrastructure de production.

Namespace :

symfony-blog

Les fichiers seront appliqués ultérieurement à un
cluster Kubernetes.

Ordre prévu :

1. Namespace
2. ConfigMap
3. Secret
4. Deployment
5. Service
6. Ingress
7. Probes
8. HPA

IMPORTANT :

Ces fichiers ne créent aucun cluster.

Ils sont uniquement des manifests Kubernetes.
EOF

echo ""
echo "=========================================="
echo " Partie 23 terminée"
echo "=========================================="
echo ""
echo "Fichiers créés :"
echo "k8s/"
echo "├── namespace.yaml"
echo "└── README.md"
echo ""
echo "Namespace prévu : symfony-blog"
echo ""
echo "⚠️ Aucun kubectl apply n'a été exécuté."
echo "⚠️ Aucun cluster Kubernetes n'a été installé."
