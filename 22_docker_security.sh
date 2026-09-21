#!/bin/bash

set -e

echo "=========================================="
echo " Partie 22 - Sécurité Docker"
echo "=========================================="

mkdir -p .github/workflows

cat > .github/workflows/security.yml <<'EOF'
name: Symfony Blog - Docker Security

on:

  push:
    branches:
      - main
      - develop

  pull_request:

jobs:

  security:

    runs-on: ubuntu-latest

    steps:

      - name: Checkout
        uses: actions/checkout@v4

      - name: Build Docker image
        run: |
          docker build \
            -f docker/php/Dockerfile \
            -t symfony-blog:security-test \
            .

      - name: Scan Docker image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'symfony-blog:security-test'
          format: 'table'
          exit-code: '1'
          ignore-unfixed: true
          severity: 'CRITICAL,HIGH'
EOF

echo ""
echo "=========================================="
echo " Partie 22 terminée"
echo "=========================================="
echo ""
echo "Pipeline créée :"
echo ".github/workflows/security.yml"
echo ""
echo "Le scan vérifie les vulnérabilités HIGH et CRITICAL."
echo ""
echo "⚠️ Aucun scan n'est exécuté localement."
echo "⚠️ Aucun cluster Kubernetes n'est créé."
