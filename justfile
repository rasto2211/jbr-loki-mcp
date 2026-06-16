registry := "europe-west4-docker.pkg.dev/gke-dev-dws-jbr/ar"
image := registry / "loki-mcp-server"
namespace := "logging"
gcp_project := "gke-dev-dws-jbr"
gsm_secret := "loki-mcp-basic-auth"

build:
    docker build --platform linux/amd64 -t {{image}}:latest .

push: build
    docker push {{image}}:latest

deploy:
    kubectl apply -f k8s/deployment.yaml

rollout: push deploy
    kubectl rollout restart deployment/loki-mcp-server -n {{namespace}}
    kubectl rollout status deployment/loki-mcp-server -n {{namespace}}

port-forward:
    kubectl port-forward svc/loki-mcp-server 8080:8080 -n {{namespace}}

logs:
    kubectl logs -n {{namespace}} -l app=loki-mcp-server -f

status:
    kubectl get pods -n {{namespace}} -l app=loki-mcp-server

sync-auth:
    gcloud secrets versions access latest --secret={{gsm_secret}} --project={{gcp_project}} \
        | kubectl create secret generic {{gsm_secret}} --from-file=auth=/dev/stdin -n {{namespace}} --dry-run=client -o yaml \
        | kubectl apply -f -

rotate-auth username="mcp":
    #!/usr/bin/env bash
    set -euo pipefail
    PASSWORD=$(openssl rand -base64 18)
    HTPASSWD=$(htpasswd -nbB "{{username}}" "$PASSWORD")
    echo -n "$HTPASSWD" | gcloud secrets versions add {{gsm_secret}} --data-file=- --project={{gcp_project}}
    echo -n "$HTPASSWD" | kubectl create secret generic {{gsm_secret}} --from-file=auth=/dev/stdin -n {{namespace}} --dry-run=client -o yaml | kubectl apply -f -
    echo "New credentials — username: {{username}}, password: $PASSWORD"
