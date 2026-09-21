#!/bin/bash

set -e

echo "=========================================="
echo " Partie 25 - Kubernetes Service + Ingress"
echo "=========================================="

mkdir -p k8s

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
      targetPort: 9000
      protocol: TCP
EOF

cat > k8s/ingress.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
  name: symfony-blog
  namespace: symfony-blog

  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"

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

echo ""
echo "=========================================="
echo " Partie 25 terminée"
echo "=========================================="
echo ""
echo "Fichiers créés :"
echo "├── k8s/service.yaml"
echo "└── k8s/ingress.yaml"
echo ""
echo "⚠️ Le domaine blog.example.com est un exemple."
echo "⚠️ Il faudra l'adapter à ton domaine."
echo "⚠️ Aucun Ingress Controller n'est installé."
echo "⚠️ Aucun cluster n'est créé."
