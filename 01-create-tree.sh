#!/usr/bin/env bash

set -e

# ============================================================
# Symfony Blog - Partie 1/8
# Création de l'arborescence DevOps
#
# IMPORTANT :
# Ce script NE :
#   - installe aucun programme
#   - ne crée aucun cluster
#   - ne démarre aucun conteneur
#   - ne modifie pas Kubernetes
#
# Il crée uniquement les dossiers et fichiers de structure.
# ============================================================

PROJECT_DIR="${HOME}/symfony-blog"

echo "=============================================="
echo " Symfony Blog - Création de l'arborescence"
echo "=============================================="

# ------------------------------------------------------------
# 1. Création du projet
# ------------------------------------------------------------

mkdir -p "$PROJECT_DIR"

cd "$PROJECT_DIR"

echo
echo "Projet : $PROJECT_DIR"

# ------------------------------------------------------------
# 2. Arborescence Symfony
# ------------------------------------------------------------

mkdir -p \
    src/Controller \
    src/Entity \
    src/Repository \
    src/Form \
    src/Service \
    src/Command \
    templates/blog \
    templates/admin \
    public \
    config/packages \
    config/routes \
    migrations \
    tests/Unit \
    tests/Functional \
    tests/Integration \
    tests/Performance

# ------------------------------------------------------------
# 3. Docker
# ------------------------------------------------------------

mkdir -p \
    docker/php \
    docker/nginx \
    docker/postgres

# ------------------------------------------------------------
# 4. Kubernetes
# ------------------------------------------------------------

mkdir -p \
    k8s/base \
    k8s/production \
    k8s/monitoring

# ------------------------------------------------------------
# 5. CI/CD
# ------------------------------------------------------------

mkdir -p \
    .github/workflows

# ------------------------------------------------------------
# 6. Monitoring
# ------------------------------------------------------------

mkdir -p \
    monitoring/prometheus \
    monitoring/grafana/dashboards \
    monitoring/grafana/datasources

# ------------------------------------------------------------
# 7. Scripts
# ------------------------------------------------------------

mkdir -p \
    scripts \
    scripts/docker \
    scripts/kubernetes \
    scripts/monitoring \
    scripts/tests

# ------------------------------------------------------------
# 8. Documentation
# ------------------------------------------------------------

mkdir -p \
    docs \
    docs/scrum \
    docs/devops \
    docs/tests \
    docs/monitoring \
    docs/kubernetes

# ------------------------------------------------------------
# 9. Fichiers principaux
# ------------------------------------------------------------

touch \
    .gitignore \
    .dockerignore \
    .env \
    .env.test \
    README.md \
    composer.json \
    composer.lock \
    phpunit.xml.dist \
    Dockerfile \
    docker-compose.yml

# ------------------------------------------------------------
# 10. Docker
# ------------------------------------------------------------

touch \
    docker/php/Dockerfile \
    docker/nginx/default.conf \
    docker/postgres/init.sql

# ------------------------------------------------------------
# 11. Kubernetes
# ------------------------------------------------------------

touch \
    k8s/namespace.yaml \
    k8s/base/configmap.yaml \
    k8s/base/secret.yaml \
    k8s/base/deployment.yaml \
    k8s/base/service.yaml \
    k8s/base/ingress.yaml \
    k8s/base/pvc.yaml \
    k8s/base/probes.yaml \
    k8s/production/deployment.yaml \
    k8s/production/service.yaml \
    k8s/production/ingress.yaml \
    k8s/production/hpa.yaml \
    k8s/production/pdb.yaml

# ------------------------------------------------------------
# 12. Monitoring
# ------------------------------------------------------------

touch \
    monitoring/prometheus/prometheus.yml \
    monitoring/prometheus/alerts.yml \
    monitoring/grafana/dashboards/symfony-blog.json \
    monitoring/grafana/datasources/prometheus.yml

# ------------------------------------------------------------
# 13. CI/CD
# ------------------------------------------------------------

touch \
    .github/workflows/ci.yml \
    .github/workflows/cd.yml \
    .github/workflows/security.yml \
    .github/workflows/performance.yml

# ------------------------------------------------------------
# 14. Tests
# ------------------------------------------------------------

touch \
    tests/Unit/.gitkeep \
    tests/Functional/.gitkeep \
    tests/Integration/.gitkeep \
    tests/Performance/.gitkeep

# ------------------------------------------------------------
# 15. Documentation
# ------------------------------------------------------------

touch \
    docs/scrum/product-backlog.md \
    docs/scrum/sprint.md \
    docs/devops/sli-slo.md \
    docs/devops/reliability.md \
    docs/tests/test-plan.md \
    docs/monitoring/monitoring.md \
    docs/kubernetes/architecture.md

# ------------------------------------------------------------
# 16. Scripts futurs
# ------------------------------------------------------------

touch \
    scripts/install.sh \
    scripts/docker/build.sh \
    scripts/docker/run.sh \
    scripts/docker/stop.sh \
    scripts/kubernetes/deploy.sh \
    scripts/kubernetes/delete.sh \
    scripts/kubernetes/status.sh \
    scripts/monitoring/start.sh \
    scripts/tests/run-tests.sh

# ------------------------------------------------------------
# 17. Affichage de l'arborescence
# ------------------------------------------------------------

echo
echo "=============================================="
echo " Arborescence créée"
echo "=============================================="
echo

if command -v tree >/dev/null 2>&1; then

    tree -a -I ".git"

else

    echo "Le programme 'tree' n'est pas installé."
    echo
    echo "Structure créée dans :"
    echo "$PROJECT_DIR"
    echo
    echo "Tu pourras afficher l'arborescence avec :"
    echo
    echo "  tree -a"
fi

echo
echo "=============================================="
echo " TERMINÉ"
echo "=============================================="
echo
echo "Aucun programme n'a été installé."
echo "Aucun conteneur n'a été lancé."
echo "Aucun cluster Kubernetes n'a été créé."
echo
echo "Projet : $PROJECT_DIR"
