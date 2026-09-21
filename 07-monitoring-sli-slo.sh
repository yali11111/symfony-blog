#!/usr/bin/env bash

set -e

# ============================================================
# PARTIE 7/8 — MONITORING, SLI/SLO ET ALERTING
# SYMFONY BLOG
#
# Ce script :
#   - crée les fichiers Prometheus
#   - crée les règles d'alertes
#   - crée la configuration Alertmanager
#   - crée le provisioning Grafana
#   - crée un dashboard Grafana de base
#
# IMPORTANT :
#   - aucun logiciel n'est installé
#   - aucun cluster n'est créé
#   - aucun conteneur n'est lancé
#   - aucun kubectl apply
# ============================================================

PROJECT_DIR="${HOME}/symfony-blog"

echo "============================================================"
echo " PARTIE 7/8 — MONITORING, SLI/SLO ET ALERTING"
echo " SYMFONY BLOG"
echo "============================================================"

mkdir -p "$PROJECT_DIR"

cd "$PROJECT_DIR"

# ============================================================
# 1. Création de l'arborescence
# ============================================================

mkdir -p monitoring/prometheus/rules
mkdir -p monitoring/alertmanager
mkdir -p monitoring/grafana/provisioning/datasources
mkdir -p monitoring/grafana/provisioning/dashboards
mkdir -p monitoring/grafana/dashboards

# ============================================================
# 2. Prometheus
# ============================================================

cat > monitoring/prometheus/prometheus.yml <<'EOF'
global:

  scrape_interval: 15s

  evaluation_interval: 15s

  external_labels:

    environment: "production"

    project: "symfony-blog"


rule_files:

  - /etc/prometheus/rules/*.yml


alerting:

  alertmanagers:

    - static_configs:

        - targets:

            - alertmanager:9093


scrape_configs:

  # ----------------------------------------------------------
  # Prometheus
  # ----------------------------------------------------------

  - job_name: "prometheus"

    static_configs:

      - targets:

          - "prometheus:9090"


  # ----------------------------------------------------------
  # Kubernetes API / composants exposant des métriques
  # ----------------------------------------------------------

  - job_name: "kubernetes-pods"

    kubernetes_sd_configs:

      - role: pod

    relabel_configs:

      - source_labels:
          - __meta_kubernetes_pod_annotation_prometheus_io_scrape

        action: keep

        regex: "true"

      - source_labels:
          - __meta_kubernetes_pod_annotation_prometheus_io_path

        action: replace

        target_label: __metrics_path__

        regex: "(.+)"

      - source_labels:
          - __address__
          - __meta_kubernetes_pod_annotation_prometheus_io_port

        action: replace

        regex: "([^:]+)(?::\\d+)?;(\\d+)"

        replacement: "$1:$2"

        target_label: __address__

      - action: labelmap

        regex: __meta_kubernetes_pod_label_(.+)

      - source_labels:
          - __meta_kubernetes_namespace

        action: replace

        target_label: namespace

      - source_labels:
          - __meta_kubernetes_pod_name

        action: replace

        target_label: pod


  # ----------------------------------------------------------
  # Symfony Blog
  #
  # L'application devra exposer /metrics pour être scrappée.
  # ----------------------------------------------------------

  - job_name: "symfony-blog"

    metrics_path: /metrics

    kubernetes_sd_configs:

      - role: pod

    relabel_configs:

      - source_labels:
          - __meta_kubernetes_pod_label_app

        action: keep

        regex: symfony-blog

EOF

# ============================================================
# 3. Règles SLI/SLO
# ============================================================

cat > monitoring/prometheus/rules/symfony-blog.yml <<'EOF'
groups:

  # ==========================================================
  # Disponibilité / erreurs HTTP
  # ==========================================================

  - name: symfony-blog-availability

    interval: 30s

    rules:

      # --------------------------------------------------------
      # Taux d'erreurs HTTP 5xx
      # --------------------------------------------------------

      - record: symfony_blog:http_5xx_ratio

        expr: |
          sum(rate(http_requests_total{job="symfony-blog",status=~"5.."}[5m]))
          /
          clamp_min(
            sum(rate(http_requests_total{job="symfony-blog"}[5m])),
            0.001
          )

      # --------------------------------------------------------
      # Taux de succès HTTP
      # --------------------------------------------------------

      - record: symfony_blog:http_success_ratio

        expr: |
          sum(rate(http_requests_total{job="symfony-blog",status=~"2..|3.."}[5m]))
          /
          clamp_min(
            sum(rate(http_requests_total{job="symfony-blog"}[5m])),
            0.001
          )


      # --------------------------------------------------------
      # Alerte SLO 5xx
      #
      # SLO :
      # < 0.1 % d'erreurs 5xx
      # --------------------------------------------------------

      - alert: SymfonyBlogHighErrorRate

        expr: |
          symfony_blog:http_5xx_ratio > 0.001

        for: 5m

        labels:

          severity: warning

          service: symfony-blog

        annotations:

          summary: "Taux d'erreur HTTP élevé"

          description: "Le taux de réponses HTTP 5xx dépasse 0,1 % depuis plus de 5 minutes."


  # ==========================================================
  # Latence
  # ==========================================================

  - name: symfony-blog-latency

    interval: 30s

    rules:

      # --------------------------------------------------------
      # p95 HTTP
      #
      # SLO :
      # p95 < 500 ms
      # --------------------------------------------------------

      - record: symfony_blog:http_latency_p95

        expr: |
          histogram_quantile(
            0.95,
            sum(
              rate(http_request_duration_seconds_bucket{job="symfony-blog"}[5m])
            )
            by (le)
          )


      - alert: SymfonyBlogHighLatencyP95

        expr: |
          symfony_blog:http_latency_p95 > 0.5

        for: 10m

        labels:

          severity: warning

          service: symfony-blog

        annotations:

          summary: "Latence HTTP p95 élevée"

          description: "Le p95 de la latence HTTP dépasse 500 ms depuis plus de 10 minutes."


  # ==========================================================
  # Kubernetes
  # ==========================================================

  - name: symfony-blog-kubernetes

    interval: 30s

    rules:

      # --------------------------------------------------------
      # Pod indisponible
      # --------------------------------------------------------

      - alert: SymfonyBlogPodUnavailable

        expr: |
          kube_deployment_status_replicas_available{
            namespace="symfony-blog",
            deployment="symfony-blog"
          }
          <
          kube_deployment_spec_replicas{
            namespace="symfony-blog",
            deployment="symfony-blog"
          }

        for: 5m

        labels:

          severity: warning

          service: symfony-blog

        annotations:

          summary: "Nombre de Pods disponibles insuffisant"

          description: "Le Deployment Symfony Blog possède moins de Pods disponibles que prévu."


      # --------------------------------------------------------
      # CPU élevé
      # --------------------------------------------------------

      - alert: SymfonyBlogHighCPU

        expr: |
          (
            sum(
              rate(container_cpu_usage_seconds_total{
                namespace="symfony-blog",
                container="symfony"
              }[5m])
            )
            /
            sum(
              kube_pod_container_resource_limits{
                namespace="symfony-blog",
                container="symfony",
                resource="cpu"
              }
            )
          ) > 0.80

        for: 10m

        labels:

          severity: warning

          service: symfony-blog

        annotations:

          summary: "CPU élevé"

          description: "La consommation CPU des Pods Symfony dépasse 80 % de leur limite."


      # --------------------------------------------------------
      # Mémoire élevée
      # --------------------------------------------------------

      - alert: SymfonyBlogHighMemory

        expr: |
          (
            sum(
              container_memory_working_set_bytes{
                namespace="symfony-blog",
                container="symfony"
              }
            )
            /
            sum(
              kube_pod_container_resource_limits{
                namespace="symfony-blog",
                container="symfony",
                resource="memory"
              }
            )
          ) > 0.80

        for: 10m

        labels:

          severity: warning

          service: symfony-blog

        annotations:

          summary: "Mémoire élevée"

          description: "La consommation mémoire des Pods Symfony dépasse 80 % de leur limite."


  # ==========================================================
  # Disponibilité globale
  # ==========================================================

  - name: symfony-blog-service

    rules:

      - alert: SymfonyBlogDown

        expr: |
          up{job="symfony-blog"} == 0

        for: 2m

        labels:

          severity: critical

          service: symfony-blog

        annotations:

          summary: "Symfony Blog indisponible"

          description: "Prometheus ne reçoit plus de métriques du service Symfony Blog."
EOF

# ============================================================
# 4. Alertmanager
# ============================================================

cat > monitoring/alertmanager/alertmanager.yml <<'EOF'
global:

  resolve_timeout: 5m


route:

  receiver: "default"

  group_by:

    - alertname

    - service

    - severity

  group_wait: 30s

  group_interval: 5m

  repeat_interval: 4h


receivers:

  - name: "default"

    # --------------------------------------------------------
    # À configurer plus tard.
    #
    # Exemples :
    # - email
    # - Slack
    # - Microsoft Teams
    # - webhook
    #
    # Aucun secret n'est placé ici.
    # --------------------------------------------------------

    # email_configs:
    #
    #   - to: "admin@example.com"
    #
    #     from: "alertmanager@example.com"
    #
    #     smarthost: "smtp.example.com:587"
    #
    #     auth_username: "..."
    #
    #     auth_password: "..."

EOF

# ============================================================
# 5. Datasource Grafana
# ============================================================

cat > monitoring/grafana/provisioning/datasources/prometheus.yml <<'EOF'
apiVersion: 1

datasources:

  - name: Prometheus

    type: prometheus

    access: proxy

    url: http://prometheus:9090

    isDefault: true

    editable: false

    jsonData:

      timeInterval: "15s"
EOF

# ============================================================
# 6. Provisioning des dashboards
# ============================================================

cat > monitoring/grafana/provisioning/dashboards/dashboards.yml <<'EOF'
apiVersion: 1

providers:

  - name: "Symfony Blog"

    orgId: 1

    folder: "Symfony Blog"

    type: file

    disableDeletion: true

    editable: true

    options:

      path: /var/lib/grafana/dashboards
EOF

# ============================================================
# 7. Dashboard Grafana
# ============================================================

cat > monitoring/grafana/dashboards/symfony-blog.json <<'EOF'
{
  "annotations": {
    "list": []
  },
  "editable": true,
  "graphTooltip": 1,
  "panels": [
    {
      "type": "stat",
      "title": "Disponibilité",
      "gridPos": {
        "h": 4,
        "w": 6,
        "x": 0,
        "y": 0
      },
      "targets": [
        {
          "expr": "symfony_blog:http_success_ratio * 100",
          "legendFormat": "Disponibilité"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "percent",
          "min": 0,
          "max": 100
        }
      }
    },
    {
      "type": "stat",
      "title": "Erreurs HTTP 5xx",
      "gridPos": {
        "h": 4,
        "w": 6,
        "x": 6,
        "y": 0
      },
      "targets": [
        {
          "expr": "symfony_blog:http_5xx_ratio * 100",
          "legendFormat": "5xx"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "percent"
        }
      }
    },
    {
      "type": "stat",
      "title": "Latence HTTP p95",
      "gridPos": {
        "h": 4,
        "w": 6,
        "x": 12,
        "y": 0
      },
      "targets": [
        {
          "expr": "symfony_blog:http_latency_p95 * 1000",
          "legendFormat": "p95"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "ms"
        }
      }
    },
    {
      "type": "timeseries",
      "title": "Latence HTTP p95",
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 4
      },
      "targets": [
        {
          "expr": "symfony_blog:http_latency_p95 * 1000",
          "legendFormat": "p95"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "ms"
        }
      }
    },
    {
      "type": "timeseries",
      "title": "Taux d'erreur HTTP 5xx",
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 4
      },
      "targets": [
        {
          "expr": "symfony_blog:http_5xx_ratio * 100",
          "legendFormat": "5xx"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "percent"
        }
      }
    },
    {
      "type": "timeseries",
      "title": "CPU Symfony",
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 12
      },
      "targets": [
        {
          "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=\"symfony-blog\",container=\"symfony\"}[5m]))",
          "legendFormat": "CPU"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "cores"
        }
      }
    },
    {
      "type": "timeseries",
      "title": "Mémoire Symfony",
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 12
      },
      "targets": [
        {
          "expr": "sum(container_memory_working_set_bytes{namespace=\"symfony-blog\",container=\"symfony\"})",
          "legendFormat": "Mémoire"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "unit": "bytes"
        }
      }
    }
  ],
  "schemaVersion": 39,
  "tags": [
    "symfony",
    "blog",
    "devops",
    "kubernetes",
    "sli",
    "slo"
  ],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "title": "Symfony Blog - DevOps",
  "uid": "symfony-blog-devops"
}
EOF

# ============================================================
# 8. Documentation SLI / SLO
# ============================================================

mkdir -p docs/devops

cat > docs/devops/sli-slo.md <<'EOF'
# SLI / SLO — Symfony Blog

## 1. Disponibilité

### SLI

Pourcentage de requêtes HTTP réussies :

```text
requêtes 2xx + 3xx
------------------- × 100
requêtes totales

SLO

Disponibilité >= 99,9 %

2. Taux d'erreur
SLI

requêtes HTTP 5xx
------------------ × 100
requêtes totales

SLO

< 0,1 %

3. Latence
SLI

Latence HTTP p95.
SLO

p95 < 500 ms

4. Récupération
SLI

MTTR :

temps entre détection de l'incident
et retour à un état opérationnel

SLO

MTTR < 2 minutes

5. Scalabilité

Les métriques suivantes sont surveillées :

    CPU

    mémoire

    nombre de Pods

    requêtes/seconde

    latence p95

    taux d'erreur

6. Alerting

Exemples d'alertes :

5xx > 0,1 %
       ↓
SymfonyBlogHighErrorRate

p95 > 500 ms
       ↓
SymfonyBlogHighLatencyP95

Pod indisponible
       ↓
SymfonyBlogPodUnavailable

Service inaccessible
       ↓
SymfonyBlogDown

7. Chaîne complète

Symfony Blog
      |
      v
Metrics
      |
      v
Prometheus
      |
      +------> SLI
      |
      +------> SLO
      |
      v
Alertmanager
      |
      v
Notification
      |
      v
Intervention
      |
      v
Récupération

8. Dashboard

Grafana permet de visualiser :

    disponibilité ;

    taux d'erreur ;

    latence p95 ;

    CPU ;

    mémoire ;

    évolution de la charge ;

    état du service.
    EOF

============================================================
9. Script de vérification
============================================================

mkdir -p scripts

cat > scripts/validate-monitoring.sh <<'EOF'
#!/usr/bin/env bash

set -e

echo "============================================================"
echo " Validation des fichiers de monitoring"
echo "============================================================"

FILES=(

monitoring/prometheus/prometheus.yml

monitoring/prometheus/rules/symfony-blog.yml

monitoring/alertmanager/alertmanager.yml

monitoring/grafana/provisioning/datasources/prometheus.yml

monitoring/grafana/provisioning/dashboards/dashboards.yml

monitoring/grafana/dashboards/symfony-blog.json

docs/devops/sli-slo.md

)

ERROR=0

for FILE in "${FILES[@]}"; do

if [ -f "$FILE" ]; then

echo "OK    $FILE"

else

echo "ERROR $FILE"

ERROR=1

fi

done

if [ "$ERROR" -ne 0 ]; then

echo
echo "Erreur : certains fichiers sont absents."

exit 1

fi

echo
echo "Tous les fichiers de monitoring sont présents."
echo
echo "Aucune installation n'a été effectuée."
echo "Aucun service n'a été démarré."
EOF

chmod +x scripts/validate-monitoring.sh
============================================================
10. Affichage final
============================================================

echo
echo "============================================================"
echo " PARTIE 7/8 TERMINÉE"
echo "============================================================"

echo
echo "Fichiers créés :"

echo "monitoring/"
echo "├── prometheus/"
echo "│ ├── prometheus.yml"
echo "│ └── rules/"
echo "│ └── symfony-blog.yml"
echo "├── alertmanager/"
echo "│ └── alertmanager.yml"
echo "└── grafana/"
echo " ├── provisioning/"
echo " │ ├── datasources/"
echo " │ │ └── prometheus.yml"
echo " │ └── dashboards/"
echo " │ └── dashboards.yml"
echo " └── dashboards/"
echo " └── symfony-blog.json"

echo
echo "Documentation :"
echo "docs/devops/sli-slo.md"

echo
echo "Validation :"
echo "./scripts/validate-monitoring.sh"

echo
echo "IMPORTANT :"
echo "- aucun logiciel installé"
echo "- aucun cluster créé"
echo "- aucun conteneur lancé"
echo "- aucun déploiement effectué"

echo
echo "============================================================"

:::

### Ce que cette partie couvre

Tu auras maintenant la chaîne :

```text
Symfony
   ↓
Metrics
   ↓
Prometheus
   ↓
SLI
   ↓
SLO
   ↓
Alertmanager
   ↓
Alertes
   ↓
Grafana
   ↓
Dashboard
