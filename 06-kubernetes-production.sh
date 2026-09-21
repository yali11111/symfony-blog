#!/usr/bin/env bash

set -e

# ============================================================
# Symfony Blog - Partie 6/8
# Création des fichiers Kubernetes
#
# IMPORTANT :
# - aucun cluster créé
# - aucune installation
# - aucun kubectl apply
# - aucun déploiement
# - aucun Pod lancé
#
# Ce script crée uniquement les manifests Kubernetes.
# ============================================================

PROJECT_DIR="${HOME}/symfony-blog"

echo "=============================================="
echo " Symfony Blog - Kubernetes"
echo "=============================================="

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# ============================================================
# 1. Arborescence
# ============================================================

mkdir -p k8s

# ============================================================
# 2. Namespace
# ============================================================

cat > k8s/namespace.yaml <<'EOF'
apiVersion: v1
kind: Namespace

metadata:
  name: symfony-blog
EOF

# ============================================================
# 3. ConfigMap
# ============================================================

cat > k8s/configmap.yaml <<'EOF'
apiVersion: v1
kind: ConfigMap

metadata:
  name: symfony-blog-config
  namespace: symfony-blog

data:

  APP_ENV: "prod"

  APP_DEBUG: "0"

  PHP_MEMORY_LIMIT: "256M"

  PHP_OPCACHE_VALIDATE_TIMESTAMPS: "0"
EOF

# ============================================================
# 4. Secret
#
# IMPORTANT :
# Ce fichier est un exemple.
# Ne jamais committer de vraies valeurs sensibles.
# ============================================================

cat > k8s/secret.yaml <<'EOF'
apiVersion: v1
kind: Secret

metadata:
  name: symfony-blog-secret
  namespace: symfony-blog

type: Opaque

stringData:

  APP_SECRET: "CHANGE_ME"

  POSTGRES_DB: "symfony"

  POSTGRES_USER: "symfony"

  POSTGRES_PASSWORD: "CHANGE_ME"

  DATABASE_URL: "postgresql://symfony:CHANGE_ME@postgres:5432/symfony?serverVersion=16&charset=utf8"
EOF

# ============================================================
# 5. Deployment Symfony
# ============================================================

cat > k8s/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment

metadata:

  name: symfony-blog

  namespace: symfony-blog

  labels:

    app: symfony-blog

spec:

  replicas: 3

  revisionHistoryLimit: 5

  strategy:

    type: RollingUpdate

    rollingUpdate:

      maxUnavailable: 0

      maxSurge: 1

  selector:

    matchLabels:

      app: symfony-blog

  template:

    metadata:

      labels:

        app: symfony-blog

    spec:

      terminationGracePeriodSeconds: 30

      containers:

        - name: symfony

          image: REGISTRY/symfony-blog:IMAGE_TAG

          imagePullPolicy: IfNotPresent

          ports:

            - name: http

              containerPort: 8000

          envFrom:

            - configMapRef:

                name: symfony-blog-config

            - secretRef:

                name: symfony-blog-secret

          resources:

            requests:

              cpu: "100m"

              memory: "128Mi"

            limits:

              cpu: "500m"

              memory: "512Mi"

          readinessProbe:

            httpGet:

              path: /health

              port: 8000

            initialDelaySeconds: 10

            periodSeconds: 10

            timeoutSeconds: 3

            failureThreshold: 3

          livenessProbe:

            httpGet:

              path: /health

              port: 8000

            initialDelaySeconds: 30

            periodSeconds: 20

            timeoutSeconds: 3

            failureThreshold: 3

          startupProbe:

            httpGet:

              path: /health

              port: 8000

            initialDelaySeconds: 5

            periodSeconds: 5

            timeoutSeconds: 3

            failureThreshold: 30
EOF

# ============================================================
# 6. Service
# ============================================================

cat > k8s/service.yaml <<'EOF'
apiVersion: v1
kind: Service

metadata:

  name: symfony-blog

  namespace: symfony-blog

spec:

  type: ClusterIP

  selector:

    app: symfony-blog

  ports:

    - name: http

      port: 80

      targetPort: 8000

      protocol: TCP
EOF

# ============================================================
# 7. Ingress
# ============================================================

cat > k8s/ingress.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:

  name: symfony-blog

  namespace: symfony-blog

  annotations:

    nginx.ingress.kubernetes.io/proxy-body-size: "20m"

    nginx.ingress.kubernetes.io/proxy-connect-timeout: "10"

    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"

spec:

  ingressClassName: nginx

  rules:

    - host: blog.example.com

      http:

        paths:

          - path: /

            pathType: Prefix

            backend:

              service:

                name: symfony-blog

                port:

                  number: 80
EOF

# ============================================================
# 8. HPA
# ============================================================

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

  minReplicas: 3

  maxReplicas: 10

  behavior:

    scaleUp:

      stabilizationWindowSeconds: 60

      policies:

        - type: Pods

          value: 2

          periodSeconds: 60

    scaleDown:

      stabilizationWindowSeconds: 300

      policies:

        - type: Percent

          value: 25

          periodSeconds: 60

  metrics:

    - type: Resource

      resource:

        name: cpu

        target:

          type: Utilization

          averageUtilization: 70

    - type: Resource

      resource:

        name: memory

        target:

          type: Utilization

          averageUtilization: 80
EOF

# ============================================================
# 9. Probes
# ============================================================

cat > k8s/probes.yaml <<'EOF'
# ============================================================
# Probes Kubernetes
#
# Les probes sont documentées ici.
# Elles sont également présentes dans deployment.yaml.
# ============================================================

apiVersion: v1
kind: ConfigMap

metadata:

  name: symfony-blog-probes-documentation

  namespace: symfony-blog

data:

  README: |
    Readiness Probe
    ---------------
    Vérifie si le Pod peut recevoir du trafic.

    Liveness Probe
    --------------
    Vérifie si le conteneur fonctionne correctement.

    Startup Probe
    -------------
    Permet aux applications ayant un démarrage lent
    de disposer de suffisamment de temps.

    Endpoint utilisé :

    /health
EOF

# ============================================================
# 10. PostgreSQL
#
# NOTE :
# Pour une vraie production, PostgreSQL devrait idéalement
# être externalisé vers un service managé ou un opérateur
# PostgreSQL. Ce manifest sert surtout à l'environnement
# de démonstration/local Kubernetes.
# ============================================================

cat > k8s/postgres.yaml <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim

metadata:

  name: postgres-data

  namespace: symfony-blog

spec:

  accessModes:

    - ReadWriteOnce

  resources:

    requests:

      storage: 10Gi

---

apiVersion: apps/v1
kind: Deployment

metadata:

  name: postgres

  namespace: symfony-blog

spec:

  replicas: 1

  selector:

    matchLabels:

      app: postgres

  template:

    metadata:

      labels:

        app: postgres

    spec:

      containers:

        - name: postgres

          image: postgres:16-alpine

          ports:

            - containerPort: 5432

          env:

            - name: POSTGRES_DB

              valueFrom:

                secretKeyRef:

                  name: symfony-blog-secret

                  key: POSTGRES_DB

            - name: POSTGRES_USER

              valueFrom:

                secretKeyRef:

                  name: symfony-blog-secret

                  key: POSTGRES_USER

            - name: POSTGRES_PASSWORD

              valueFrom:

                secretKeyRef:

                  name: symfony-blog-secret

                  key: POSTGRES_PASSWORD

          resources:

            requests:

              cpu: "100m"

              memory: "256Mi"

            limits:

              cpu: "500m"

              memory: "1Gi"

          volumeMounts:

            - name: postgres-data

              mountPath: /var/lib/postgresql/data

          readinessProbe:

            exec:

              command:

                - sh

                - -c

                - pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"

            initialDelaySeconds: 10

            periodSeconds: 10

      volumes:

        - name: postgres-data

          persistentVolumeClaim:

            claimName: postgres-data

---

apiVersion: v1
kind: Service

metadata:

  name: postgres

  namespace: symfony-blog

spec:

  type: ClusterIP

  selector:

    app: postgres

  ports:

    - port: 5432

      targetPort: 5432
EOF

# ============================================================
# 11. PodDisruptionBudget
# ============================================================

cat > k8s/pdb.yaml <<'EOF'
apiVersion: policy/v1
kind: PodDisruptionBudget

metadata:

  name: symfony-blog

  namespace: symfony-blog

spec:

  minAvailable: 2

  selector:

    matchLabels:

      app: symfony-blog
EOF

# ============================================================
# 12. NetworkPolicy
# ============================================================

cat > k8s/network-policy.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy

metadata:

  name: symfony-blog

  namespace: symfony-blog

spec:

  podSelector:

    matchLabels:

      app: symfony-blog

  policyTypes:

    - Ingress

    - Egress

  ingress:

    - from:

        - namespaceSelector: {}

  egress:

    - to:

        - podSelector:

            matchLabels:

              app: postgres

      ports:

        - protocol: TCP

          port: 5432

    - ports:

        - protocol: TCP

          port: 53

        - protocol: UDP

          port: 53
EOF

# ============================================================
# 13. Kustomization
# ============================================================

cat > k8s/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization

namespace: symfony-blog

resources:

  - namespace.yaml

  - configmap.yaml

  - secret.yaml

  - deployment.yaml

  - service.yaml

  - ingress.yaml

  - hpa.yaml

  - probes.yaml

  - postgres.yaml

  - pdb.yaml

  - network-policy.yaml
EOF

# ============================================================
# 14. Kustomization production
# ============================================================

mkdir -p k8s/overlays/production

cat > k8s/overlays/production/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1

kind: Kustomization

namespace: symfony-blog

resources:

  - ../../
EOF

cat > k8s/overlays/production/README.md <<'EOF'
# Production

Cette overlay représente la configuration destinée
au déploiement Kubernetes de production.

Avant déploiement réel :

- remplacer l'image Docker ;
- configurer les secrets ;
- configurer le domaine ;
- configurer TLS ;
- vérifier les ressources ;
- vérifier le stockage ;
- prévoir les sauvegardes PostgreSQL ;
- tester les procédures de restauration.
EOF

# ============================================================
# 15. Validation statique
# ============================================================

cat > scripts/validate-k8s.sh <<'EOF'
#!/usr/bin/env bash

set -e

echo "=============================================="
echo " Validation statique Kubernetes"
echo "=============================================="

FILES=(

    k8s/namespace.yaml

    k8s/configmap.yaml

    k8s/secret.yaml

    k8s/deployment.yaml

    k8s/service.yaml

    k8s/ingress.yaml

    k8s/hpa.yaml

    k8s/probes.yaml

    k8s/postgres.yaml

    k8s/pdb.yaml

    k8s/network-policy.yaml

    k8s/kustomization.yaml

)

for FILE in "${FILES[@]}"; do

    if [ -f "$FILE" ]; then

        echo "OK : $FILE"

    else

        echo "ERREUR : $FILE absent"

        exit 1

    fi

done

echo
echo "Tous les manifests sont présents."

echo
echo "IMPORTANT : aucun manifest n'a été appliqué."
EOF

chmod +x scripts/validate-k8s.sh

# ============================================================
# 16. Documentation Kubernetes
# ============================================================

cat > docs/devops/kubernetes.md <<'EOF'
# Kubernetes - Symfony Blog

## Architecture

```text
                    Internet
                       |
                       v
                    Ingress
                       |
                       v
                 Symfony Service
                       |
             +---------+---------+
             |         |         |
             v         v         v
           Pod 1     Pod 2     Pod 3
             |         |         |
             +---------+---------+
                       |
                       v
                   PostgreSQL

Haute disponibilité

Le Deployment démarre avec :

replicas: 3

L'objectif est de permettre au service de continuer
à fonctionner si un Pod devient indisponible.
Rolling Update

Les mises à jour utilisent :

maxUnavailable: 0
maxSurge: 1

Le but est de limiter l'interruption de service
pendant un déploiement.
Health Checks

Trois mécanismes sont prévus :
Startup Probe

Vérifie le démarrage de l'application.
Readiness Probe

Détermine si le Pod peut recevoir du trafic.
Liveness Probe

Détermine si le conteneur doit être redémarré.

Endpoint :

/health

Autoscaling

Le HPA utilise :

CPU > 70 %

et :

RAM > 80 %

avec :

minimum : 3 Pods
maximum : 10 Pods

Les valeurs devront être ajustées après mesure.
PDB

Le PodDisruptionBudget garantit qu'au moins :

2 Pods

restent disponibles lors des disruptions volontaires.
Sécurité

Une NetworkPolicy limite les communications.

Le Secret Kubernetes contient les valeurs sensibles.

En production réelle, il est recommandé d'utiliser
un gestionnaire de secrets adapté plutôt que de conserver
des secrets en clair dans Git.
Base de données

Le manifest PostgreSQL est adapté à une démonstration
ou à un environnement Kubernetes contrôlé.

Pour une production importante, il est préférable
d'étudier :

    PostgreSQL managé ;

    réplication ;

    sauvegardes ;

    restauration ;

    haute disponibilité ;

    monitoring ;

    chiffrement ;

    gestion des secrets.

Déploiement prévu

GitHub
   |
   v
GitHub Actions
   |
   v
Docker Registry
   |
   v
Kubernetes
   |
   +--> Deployment
   |
   +--> Service
   |
   +--> Ingress
   |
   +--> HPA
   |
   +--> Monitoring

EOF
============================================================
17. Résumé
============================================================

echo
echo "=============================================="
echo " Partie 6/8 terminée"
echo "=============================================="

echo
echo "Arborescence Kubernetes :"

echo "k8s/"
echo "├── namespace.yaml"
echo "├── configmap.yaml"
echo "├── secret.yaml"
echo "├── deployment.yaml"
echo "├── service.yaml"
echo "├── ingress.yaml"
echo "├── hpa.yaml"
echo "├── probes.yaml"
echo "├── postgres.yaml"
echo "├── pdb.yaml"
echo "├── network-policy.yaml"
echo "├── kustomization.yaml"
echo "└── overlays/"
echo " └── production/"
echo " ├── kustomization.yaml"
echo " └── README.md"

echo
echo "IMPORTANT :"
echo "- aucun cluster créé"
echo "- aucun Pod lancé"
echo "- aucun service Kubernetes créé"
echo "- aucun kubectl apply"
echo "- aucune installation"

echo
echo "=============================================="

:::

### Ce que cette partie ajoute

Tu as maintenant les éléments nécessaires pour démontrer :

- **haute disponibilité** : 3 Pods Symfony ;
- **résilience** : remplacement automatique d'un Pod ;
- **Rolling Update** ;
- **readiness/liveness/startup probes** ;
- **scalabilité horizontale** avec HPA ;
- **PDB** pour les disruptions ;
- **Ingress** pour l'accès HTTP ;
- **Service** pour distribuer le trafic ;
- **NetworkPolicy** ;
- **PostgreSQL avec stockage persistant** ;
- une première séparation **production avec Kustomize**.

Un point important : **je ne considère pas le PostgreSQL du fichier ci-dessus comme une architecture de base de données HA de production**. Pour une vraie production, il faudra traiter séparément réplication, sauvegardes/restauration, stockage et éventuellement PostgreSQL managé/operator.

Il reste ensuite :

```text
1. Arborescence
2. Docker
3. Configuration Docker
4. Tests
5. CI/CD
6. Kubernetes          ← terminé
7. Monitoring          ← Prometheus + Grafana + alertes + SLI/SLO
8. Automatisation finale / intégration production
