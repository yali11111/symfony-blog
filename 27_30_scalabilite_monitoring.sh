#!/bin/bash

set -e

echo "======================================================"
echo " Parties 27 à 30 - Scalabilité + Monitoring + Alertes"
echo " Symfony Blog / Kubernetes"
echo "======================================================"

mkdir -p k8s/monitoring
mkdir -p monitoring/prometheus
mkdir -p monitoring/grafana/dashboards

# ======================================================
# PARTIE 27 - HORIZONTAL POD AUTOSCALER
# ======================================================

echo ""
echo "[27/30] Création du HPA..."

cat > k8s/hpa.yaml <<'EOF'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler

metadata:
  name: symfony-blog
  namespace: symfony-blog

spec:

  scaleTargetRef:

    apiVersion: apps/v1
    kind: Deployment
    name: symfony-blog

  minReplicas: 2
  maxReplicas: 10

  behavior:

    scaleUp:

      stabilizationWindowSeconds: 60

      policies:
        - type: Percent
          value: 100
          periodSeconds: 60

    scaleDown:

      stabilizationWindowSeconds: 300

      policies:
        - type: Percent
          value: 50
          periodSeconds: 60

  metrics:

    - type: Resource

      resource:

        name: cpu

        target:

          type: Utilization
          averageUtilization: 70
EOF

echo "✓ HPA créé"
echo "  Minimum : 2 Pods"
echo "  Maximum : 10 Pods"
echo "  Seuil CPU : 70 %"


# ======================================================
# PARTIE 28 - PROMETHEUS
# ======================================================

echo ""
echo "[28/30] Création de la configuration Prometheus..."

cat > monitoring/prometheus/prometheus.yml <<'EOF'
global:

  scrape_interval: 15s

  evaluation_interval: 15s


rule_files:

  - /etc/prometheus/alerts.yml


scrape_configs:

  - job_name: "prometheus"

    static_configs:

      - targets:
          - "localhost:9090"


  - job_name: "symfony-blog"

    metrics_path: /metrics

    static_configs:

      - targets:
          - "symfony-blog.symfony-blog.svc.cluster.local:80"
EOF


cat > monitoring/prometheus/alerts.yml <<'EOF'
groups:

  - name: symfony-blog

    rules:

      # ----------------------------------------------
      # Disponibilité
      # ----------------------------------------------

      - alert: SymfonyBlogDown

        expr: up{job="symfony-blog"} == 0

        for: 2m

        labels:
          severity: critical

        annotations:

          summary: "Symfony Blog indisponible"

          description: >
            Prometheus ne reçoit plus de métriques
            depuis Symfony Blog depuis plus de 2 minutes.


      # ----------------------------------------------
      # CPU
      # ----------------------------------------------

      - alert: SymfonyBlogHighCPU

        expr: |
          avg(
            rate(
              container_cpu_usage_seconds_total{
                namespace="symfony-blog"
              }[5m]
            )
          ) > 0.70

        for: 5m

        labels:
          severity: warning

        annotations:

          summary: "CPU élevée"

          description: >
            La consommation CPU du namespace Symfony Blog
            est élevée depuis plus de 5 minutes.


      # ----------------------------------------------
      # Mémoire
      # ----------------------------------------------

      - alert: SymfonyBlogHighMemory

        expr: |
          container_memory_working_set_bytes{
            namespace="symfony-blog"
          }
          /
          container_spec_memory_limit_bytes{
            namespace="symfony-blog"
          }
          > 0.80

        for: 5m

        labels:
          severity: warning

        annotations:

          summary: "Mémoire élevée"

          description: >
            Un conteneur Symfony Blog utilise plus de 80 %
            de sa mémoire disponible.
EOF

echo "✓ Configuration Prometheus créée"


# ======================================================
# PARTIE 29 - GRAFANA
# ======================================================

echo ""
echo "[29/30] Création de la configuration Grafana..."

cat > monitoring/grafana/datasource.yml <<'EOF'
apiVersion: 1

datasources:

  - name: Prometheus

    type: prometheus

    access: proxy

    url: http://prometheus:9090

    isDefault: true

    editable: false
EOF


cat > monitoring/grafana/dashboards/dashboard-provider.yml <<'EOF'
apiVersion: 1

providers:

  - name: "Symfony Blog"

    orgId: 1

    folder: "Symfony Blog"

    type: file

    disableDeletion: true

    editable: false

    options:

      path: /var/lib/grafana/dashboards
EOF


cat > monitoring/grafana/dashboards/symfony-blog.json <<'EOF'
{
  "title": "Symfony Blog - Monitoring",
  "uid": "symfony-blog",
  "timezone": "browser",
  "schemaVersion": 39,
  "version": 1,

  "panels": [

    {
      "title": "Disponibilité",
      "type": "stat",
      "gridPos": {
        "x": 0,
        "y": 0,
        "w": 6,
        "h": 4
      },
      "targets": [
        {
          "expr": "up{job=\"symfony-blog\"}"
        }
      ]
    },

    {
      "title": "CPU",
      "type": "timeseries",
      "gridPos": {
        "x": 6,
        "y": 0,
        "w": 9,
        "h": 4
      },
      "targets": [
        {
          "expr": "rate(container_cpu_usage_seconds_total[5m])"
        }
      ]
    },

    {
      "title": "Mémoire",
      "type": "timeseries",
      "gridPos": {
        "x": 15,
        "y": 0,
        "w": 9,
        "h": 4
      },
      "targets": [
        {
          "expr": "container_memory_working_set_bytes"
        }
      ]
    },

    {
      "title": "Requêtes HTTP",
      "type": "timeseries",
      "gridPos": {
        "x": 0,
        "y": 4,
        "w": 12,
        "h": 6
      },
      "targets": [
        {
          "expr": "rate(http_requests_total[5m])"
        }
      ]
    },

    {
      "title": "Latence HTTP",
      "type": "timeseries",
      "gridPos": {
        "x": 12,
        "y": 4,
        "w": 12,
        "h": 6
      },
      "targets": [
        {
          "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
        }
      ]
    }

  ]
}
EOF

echo "✓ Configuration Grafana créée"


# ======================================================
# PARTIE 30 - SLI / SLO / ALERTES
# ======================================================

echo ""
echo "[30/30] Création des règles SLI/SLO..."

cat > k8s/monitoring/slo-rules.yaml <<'EOF'
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule

metadata:

  name: symfony-blog-slo

  namespace: symfony-blog

spec:

  groups:

    - name: symfony-blog-slo

      rules:

        # --------------------------------------------
        # SLO disponibilité
        # Objectif : >= 99.9 %
        # --------------------------------------------

        - record: symfony_blog:availability:ratio

          expr: |
            sum(
              rate(http_requests_total{
                namespace="symfony-blog",
                status=~"2..|3.."
              }[5m])
            )
            /
            sum(
              rate(http_requests_total{
                namespace="symfony-blog"
              }[5m])
            )


        # --------------------------------------------
        # Taux d'erreur
        # Objectif : < 0.1 %
        # --------------------------------------------

        - record: symfony_blog:error_rate

          expr: |
            sum(
              rate(http_requests_total{
                namespace="symfony-blog",
                status=~"5.."
              }[5m])
            )
            /
            sum(
              rate(http_requests_total{
                namespace="symfony-blog"
              }[5m])
            )


        # --------------------------------------------
        # Latence P95
        # Objectif : < 500 ms
        # --------------------------------------------

        - record: symfony_blog:http_latency:p95

          expr: |
            histogram_quantile(
              0.95,
              sum(
                rate(
                  http_request_duration_seconds_bucket{
                    namespace="symfony-blog"
                  }[5m]
                )
              ) by (le)
            )


        # --------------------------------------------
        # Alerte disponibilité
        # --------------------------------------------

        - alert: SymfonyBlogAvailabilitySLO

          expr: |
            symfony_blog:availability:ratio < 0.999

          for: 5m

          labels:

            severity: critical

          annotations:

            summary: "SLO de disponibilité dépassé"

            description: >
              La disponibilité du Symfony Blog
              est inférieure à 99.9 %.


        # --------------------------------------------
        # Alerte taux d'erreur
        # --------------------------------------------

        - alert: SymfonyBlogErrorRateSLO

          expr: |
            symfony_blog:error_rate > 0.001

          for: 5m

          labels:

            severity: critical

          annotations:

            summary: "Taux d'erreur trop élevé"

            description: >
              Le taux de réponses HTTP 5xx
              dépasse 0.1 %.


        # --------------------------------------------
        # Alerte latence
        # --------------------------------------------

        - alert: SymfonyBlogLatencySLO

          expr: |
            symfony_blog:http_latency:p95 > 0.5

          for: 5m

          labels:

            severity: warning

          annotations:

            summary: "SLO de latence dépassé"

            description: >
              Le P95 de la latence HTTP dépasse
              500 millisecondes.
EOF

echo "✓ SLI/SLO et alertes créés"


# ======================================================
# README MONITORING
# ======================================================

cat > monitoring/README.md <<'EOF'
# Monitoring Symfony Blog

## Architecture

Symfony Blog
     |
     v
 Prometheus
     |
     +------------------+
     |                  |
     v                  v
  Grafana            Alertes
     |
     v
 Dashboards


## SLI

Les indicateurs suivis sont :

- disponibilité
- taux d'erreur HTTP 5xx
- latence P95
- CPU
- mémoire
- nombre de requêtes


## SLO

Objectifs proposés :

Disponibilité :
>= 99.9 %

Taux d'erreur :
< 0.1 %

Latence P95 :
< 500 ms


## Scalabilité

HPA :

Minimum :
2 Pods

Maximum :
10 Pods

Seuil CPU :
70 %


## Important

Les fichiers de ce dossier sont des manifests/configurations.

Ils ne déploient pas automatiquement Prometheus ou Grafana.

Ils nécessitent une stack de monitoring compatible Kubernetes,
par exemple Prometheus Operator / kube-prometheus-stack.
EOF


# ======================================================
# VERIFICATION
# ======================================================

echo ""
echo "======================================================"
echo " Parties 27 à 30 terminées"
echo "======================================================"

echo ""
echo "Fichiers créés :"

echo ""
echo "Kubernetes :"
echo "  k8s/hpa.yaml"
echo "  k8s/monitoring/slo-rules.yaml"

echo ""
echo "Prometheus :"
echo "  monitoring/prometheus/prometheus.yml"
echo "  monitoring/prometheus/alerts.yml"

echo ""
echo "Grafana :"
echo "  monitoring/grafana/datasource.yml"
echo "  monitoring/grafana/dashboards/dashboard-provider.yml"
echo "  monitoring/grafana/dashboards/symfony-blog.json"

echo ""
echo "Documentation :"
echo "  monitoring/README.md"

echo ""
echo "======================================================"
echo " Aucune installation Kubernetes effectuée."
echo " Aucun cluster créé."
echo " Aucun kubectl apply exécuté."
echo "======================================================"
