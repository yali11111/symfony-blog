#!/bin/bash

set -e

echo "=========================================="
echo " Partie 24 - Kubernetes Deployment"
echo "=========================================="

mkdir -p k8s

cat > k8s/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment

metadata:
  name: symfony-blog
  namespace: symfony-blog

spec:

  replicas: 2

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

      containers:

        - name: symfony

          image: ghcr.io/CHANGE_ME/symfony-blog:latest

          imagePullPolicy: IfNotPresent

          ports:
            - containerPort: 9000

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
            tcpSocket:
              port: 9000
            initialDelaySeconds: 10
            periodSeconds: 10

          livenessProbe:
            tcpSocket:
              port: 9000
            initialDelaySeconds: 30
            periodSeconds: 20
EOF

echo ""
echo "=========================================="
echo " Partie 24 terminée"
echo "=========================================="
echo ""
echo "Fichier créé :"
echo "k8s/deployment.yaml"
echo ""
echo "Configuration :"
echo "Pods Symfony : 2"
echo "RollingUpdate : activé"
echo "Resources : CPU + RAM"
echo "Probes : readiness + liveness"
echo ""
echo "⚠️ Remplacer CHANGE_ME avant utilisation."
echo "⚠️ Aucun cluster Kubernetes n'est créé."
echo "⚠️ Aucun kubectl apply n'est exécuté."
