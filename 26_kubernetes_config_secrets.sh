#!/bin/bash

set -e

echo "=========================================="
echo " Partie 26 - ConfigMap + Secret + Probes"
echo "=========================================="

mkdir -p k8s

cat > k8s/configmap.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap

metadata:
  name: symfony-blog-config
  namespace: symfony-blog

data:

  APP_ENV: "prod"

  APP_DEBUG: "0"

  DATABASE_HOST: "mysql"

  DATABASE_PORT: "3306"

  DATABASE_NAME: "symfony"
EOF

cat > k8s/secret.example.yaml <<'EOF'
apiVersion: v1
kind: Secret

metadata:
  name: symfony-blog-secret
  namespace: symfony-blog

type: Opaque

stringData:

  DATABASE_USER: "CHANGE_ME"

  DATABASE_PASSWORD: "CHANGE_ME"

  APP_SECRET: "CHANGE_ME"
EOF

cat > k8s/probes.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap

metadata:
  name: symfony-blog-health
  namespace: symfony-blog

data:

  README: |
    Les probes de santé sont configurées dans deployment.yaml.

    readinessProbe :
    indique si le Pod peut recevoir du trafic.

    livenessProbe :
    indique si le conteneur doit être redémarré.

    Une vraie application Symfony peut également
    exposer un endpoint /health dédié.
EOF

echo ""
echo "=========================================="
echo " Partie 26 terminée"
echo "=========================================="
echo ""
echo "Fichiers créés :"
echo "├── k8s/configmap.yaml"
echo "├── k8s/secret.example.yaml"
echo "└── k8s/probes.yaml"
echo ""
echo "⚠️ secret.example.yaml contient uniquement des valeurs fictives."
echo "⚠️ Ne jamais committer un vrai mot de passe."
echo "⚠️ Aucun Secret n'est appliqué au cluster."
echo "⚠️ Aucun cluster Kubernetes n'est créé."
