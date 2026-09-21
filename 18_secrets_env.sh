#!/bin/bash

set -e

echo "=========================================="
echo " Partie 20 - GitHub Actions CD"
echo "=========================================="

mkdir -p .github/workflows

cat > .github/workflows/cd.yml <<'EOF'
name: Symfony Blog - CD

on:

  workflow_run:
    workflows:
      - "Symfony Blog - CI"
    types:
      - completed

jobs:

  build:

    if: >
      ${{ github.event.workflow_run.conclusion == 'success' }}

    runs-on: ubuntu-latest

    steps:

      - name: Checkout
        uses: actions/checkout@v4

      - name: Docker Build
        run: |
          docker build \
            -f docker/php/Dockerfile \
            -t symfony-blog:${{ github.sha }} \
            .

      - name: Docker Image Check
        run: |
          docker image inspect symfony-blog:${{ github.sha }}

      - name: Build successful
        run: |
          echo "✅ Image Docker construite avec succès."
          echo "Image : symfony-blog:${{ github.sha }}"
EOF

echo ""
echo "=========================================="
echo " Partie 20 terminée"
echo "=========================================="
echo ""
echo "Pipeline CD créée :"
echo ".github/workflows/cd.yml"
echo ""
echo "Étape actuelle :"
echo "CI → Build Docker → Validation"
echo ""
echo "⚠️ Pas de Push vers un Registry."
echo "⚠️ Pas de déploiement Kubernetes."
echo "⚠️ Aucun cluster Kubernetes n'est créé."
