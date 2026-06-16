registry := "europe-west4-docker.pkg.dev/gke-dev-dws-jbr/ar"
image := registry / "loki-mcp-server"
namespace := "logging"

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
