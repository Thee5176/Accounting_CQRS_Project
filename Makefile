.PHONY: help minikube-start minikube-stop minikube-clean k8s-setup k8s-check k8s-clean k8s-logs k8s-describe-pods

MINIKUBE_PROFILE := accounting-cqrs
NAMESPACE := accounting-core
K8S_DIR := kubernetes

# Color output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

help:
	@echo "$(BLUE)=== Kubernetes Development Environment ===$(NC)"
	@echo ""
	@echo "$(YELLOW)Minikube Commands:$(NC)"
	@echo "  make minikube-start      - Start minikube with KVM2 driver"
	@echo "  make minikube-stop       - Stop minikube"
	@echo "  make minikube-clean      - Delete minikube cluster"
	@echo ""
	@echo "$(YELLOW)Kubernetes Setup Commands:$(NC)"
	@echo "  make k8s-setup           - Setup and apply all Kubernetes resources"
	@echo "  make k8s-secrets-generate - Generate k8s secrets from env.properties"
	@echo "  make k8s-check           - Check all Kubernetes resources"
	@echo "  make k8s-logs            - View logs for all deployments"
	@echo "  make k8s-describe-pods   - Describe all pods"
	@echo "  make k8s-clean           - Delete all Kubernetes resources"
	@echo ""
	@echo "$(YELLOW)Image & Deployment Update Commands:$(NC)"
	@echo "  make update-images       - Update all images to latest and rollout"
	@echo "  make update-image-frontend - Update frontend image only"
	@echo "  make update-image-command  - Update command service image only"
	@echo "  make update-image-query    - Update query service image only"
	@echo "  make restart-deployments - Restart all deployments (pulls new images)"
	@echo ""
	@echo "$(YELLOW)All-in-One Commands:$(NC)"
	@echo "  make start               - Start minikube and setup Kubernetes"
	@echo "  make stop                - Stop and clean minikube"
	@echo ""

# ============================================================================
# MINIKUBE COMMANDS
# ============================================================================

minikube-start:
	@echo "$(BLUE)Starting minikube with KVM2 driver...$(NC)"
	@minikube start \
		--profile=$(MINIKUBE_PROFILE) \
		--driver=kvm2 \
		--cpus=4 \
		--memory=8192 \
		--disk-size=50gb \
		--addons=ingress \
		--addons=metrics-server
	@echo "$(GREEN)✓ Minikube started successfully$(NC)"
	@echo ""
	@echo "$(BLUE)Setting up context...$(NC)"
	@kubectl config use-context $(MINIKUBE_PROFILE)
	@echo "$(GREEN)✓ Context set to $(MINIKUBE_PROFILE)$(NC)"

minikube-stop:
	@echo "$(BLUE)Stopping minikube...$(NC)"
	@minikube stop --profile=$(MINIKUBE_PROFILE)
	@echo "$(GREEN)✓ Minikube stopped$(NC)"

minikube-clean: minikube-stop
	@echo "$(BLUE)Deleting minikube cluster...$(NC)"
	@minikube delete --profile=$(MINIKUBE_PROFILE)
	@echo "$(GREEN)✓ Minikube cluster deleted$(NC)"

minikube-status:
	@echo "$(BLUE)Checking minikube status...$(NC)"
	@minikube status --profile=$(MINIKUBE_PROFILE)

# ============================================================================
# KUBERNETES SETUP COMMANDS
# ============================================================================

k8s-namespace:
	@echo "$(BLUE)Creating namespace: $(NAMESPACE)...$(NC)"
	@kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@echo "$(GREEN)✓ Namespace ready$(NC)"

k8s-secrets-generate:
	@echo "$(BLUE)Generating Kubernetes secrets from env.properties...$(NC)"
	@chmod +x $(K8S_DIR)/scripts/create-secrets.sh
	@$(K8S_DIR)/scripts/create-secrets.sh

k8s-secrets:
	@echo "$(BLUE)Applying secrets...$(NC)"
	@kubectl apply -f $(K8S_DIR)/secret/ -n $(NAMESPACE)
	@echo "$(GREEN)✓ Secrets applied$(NC)"

k8s-services:
	@echo "$(BLUE)Applying ClusterIP services...$(NC)"
	@kubectl apply -f $(K8S_DIR)/service/ -n $(NAMESPACE)
	@echo "$(GREEN)✓ Services applied$(NC)"

k8s-network-policy:
	@echo "$(BLUE)Applying network policies...$(NC)"
	@kubectl apply -f $(K8S_DIR)/network-policy/ -n $(NAMESPACE)
	@echo "$(GREEN)✓ Network policies applied$(NC)"

k8s-deployments:
	@echo "$(BLUE)Applying deployments...$(NC)"
	@kubectl apply -f $(K8S_DIR)/deployment/ -n $(NAMESPACE)
	@echo "$(YELLOW)Waiting for deployments to be ready...$(NC)"
	@kubectl rollout status deployment/frontend-deployment -n $(NAMESPACE) --timeout=5m
	@kubectl rollout status deployment/command-deployment -n $(NAMESPACE) --timeout=5m
	@kubectl rollout status deployment/query-deployment -n $(NAMESPACE) --timeout=5m
	@echo "$(GREEN)✓ Deployments ready$(NC)"

k8s-ingress:
	@echo "$(BLUE)Applying ingress...$(NC)"
	@kubectl apply -f $(K8S_DIR)/ingress/ -n $(NAMESPACE)
	@echo "$(GREEN)✓ Ingress applied$(NC)"

k8s-setup: k8s-namespace k8s-secrets-generate k8s-secrets k8s-services k8s-network-policy k8s-deployments k8s-ingress
	@echo ""
	@echo "$(GREEN)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║  Kubernetes setup completed successfully!                  ║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(BLUE)Next steps:$(NC)"
	@echo "  1. Check resources: make k8s-check"
	@echo "  2. View logs:       make k8s-logs"
	@echo "  3. Port forward:    kubectl port-forward -n $(NAMESPACE) svc/frontend-service 80:80"
	@echo ""

# ============================================================================
# KUBERNETES CHECK & MONITOR COMMANDS
# ============================================================================

k8s-check:
	@echo "$(BLUE)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║  KUBERNETES RESOURCES STATUS                               ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)--- Namespace ---$(NC)"
	@kubectl get namespace $(NAMESPACE) -o wide || echo "$(RED)Namespace not found$(NC)"
	@echo ""
	@echo "$(YELLOW)--- Deployments ---$(NC)"
	@kubectl get deployment -n $(NAMESPACE) -o wide
	@echo ""
	@echo "$(YELLOW)--- Pods ---$(NC)"
	@kubectl get pods -n $(NAMESPACE) -o wide
	@echo ""
	@echo "$(YELLOW)--- Services ---$(NC)"
	@kubectl get service -n $(NAMESPACE) -o wide
	@echo ""
	@echo "$(YELLOW)--- Ingress ---$(NC)"
	@kubectl get ingress -n $(NAMESPACE) -o wide
	@echo ""
	@echo "$(YELLOW)--- Network Policies ---$(NC)"
	@kubectl get networkpolicy -n $(NAMESPACE) -o wide
	@echo ""
	@echo "$(YELLOW)--- Secrets ---$(NC)"
	@kubectl get secret -n $(NAMESPACE) -o wide
	@echo ""

k8s-describe-pods:
	@echo "$(BLUE)Describing all pods in $(NAMESPACE)...$(NC)"
	@kubectl describe pods -n $(NAMESPACE)

k8s-logs:
	@echo "$(BLUE)Tailing logs from all deployments...$(NC)"
	@echo "$(YELLOW)Frontend logs:$(NC)"
	@kubectl logs -n $(NAMESPACE) -l app=react-frontend --tail=50 -f &
	@echo "$(YELLOW)Command service logs:$(NC)"
	@kubectl logs -n $(NAMESPACE) -l app=springboot-command --tail=50 -f &
	@echo "$(YELLOW)Query service logs:$(NC)"
	@kubectl logs -n $(NAMESPACE) -l app=springboot-query --tail=50 -f &
	@wait

k8s-port-forward:
	@echo "$(BLUE)Setting up port forwards...$(NC)"
	@echo "$(YELLOW)Frontend: http://localhost:3000$(NC)"
	@kubectl port-forward -n $(NAMESPACE) svc/frontend-service 3000:80 &
	@echo "$(YELLOW)Command service: http://localhost:8080$(NC)"
	@kubectl port-forward -n $(NAMESPACE) svc/command-service 8080:8080 &
	@echo "$(YELLOW)Query service: http://localhost:8081$(NC)"
	@kubectl port-forward -n $(NAMESPACE) svc/query-service 8081:8081 &
	@echo "$(GREEN)Port forwards established. Press Ctrl+C to stop.$(NC)"
	@wait

# ============================================================================
# KUBERNETES CLEANUP COMMANDS
# ============================================================================

k8s-clean:
	@echo "$(RED)Deleting all Kubernetes resources in $(NAMESPACE)...$(NC)"
	@kubectl delete namespace $(NAMESPACE) --ignore-not-found=true
	@echo "$(GREEN)✓ All resources cleaned up$(NC)"

# ============================================================================
# COMBINED COMMANDS
# ============================================================================

start: minikube-start k8s-setup k8s-check
	@echo ""
	@echo "$(GREEN)╔════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║  Development environment is ready!                         ║$(NC)"
	@echo "$(GREEN)╚════════════════════════════════════════════════════════════╝$(NC)"

stop: k8s-clean minikube-stop

status:
	@echo "$(BLUE)Minikube Status:$(NC)"
	@minikube status --profile=$(MINIKUBE_PROFILE)
	@echo ""
	@echo "$(BLUE)Kubernetes Resources:$(NC)"
	@kubectl get all -n $(NAMESPACE) || echo "Namespace not found"

# ============================================================================
# DEVELOPMENT HELPERS
# ============================================================================

shell-frontend:
	@kubectl exec -it -n $(NAMESPACE) $$(kubectl get pod -n $(NAMESPACE) -l app=react-frontend -o jsonpath='{.items[0].metadata.name}') -- /bin/sh

shell-command:
	@kubectl exec -it -n $(NAMESPACE) $$(kubectl get pod -n $(NAMESPACE) -l app=springboot-command -o jsonpath='{.items[0].metadata.name}') -- /bin/bash

shell-query:
	@kubectl exec -it -n $(NAMESPACE) $$(kubectl get pod -n $(NAMESPACE) -l app=springboot-query -o jsonpath='{.items[0].metadata.name}') -- /bin/bash

restart-deployments:
	@echo "$(BLUE)Restarting all deployments...$(NC)"
	@kubectl rollout restart deployment -n $(NAMESPACE)
	@echo "$(GREEN)✓ Deployments restarted$(NC)"

update-images:
	@echo "$(BLUE)Updating all container images to latest...$(NC)"
	@kubectl set image deployment/frontend-deployment \
		react-frontend=thee5176/react_cqrs_ui:latest \
		-n $(NAMESPACE)
	@kubectl set image deployment/command-deployment \
		springboot-command=thee5176/springboot_cqrs_command:latest \
		-n $(NAMESPACE)
	@kubectl set image deployment/query-deployment \
		springboot-query=thee5176/springboot_cqrs_query:latest \
		-n $(NAMESPACE)
	@echo "$(GREEN)✓ Images updated. Waiting for rollout...$(NC)"
	@kubectl rollout status deployment/frontend-deployment -n $(NAMESPACE) --timeout=5m
	@kubectl rollout status deployment/command-deployment -n $(NAMESPACE) --timeout=5m
	@kubectl rollout status deployment/query-deployment -n $(NAMESPACE) --timeout=5m
	@echo "$(GREEN)✓ All deployments rolled out successfully$(NC)"

update-image-frontend:
	@echo "$(BLUE)Updating frontend image...$(NC)"
	@kubectl set image deployment/frontend-deployment \
		react-frontend=thee5176/react_cqrs_ui:latest \
		-n $(NAMESPACE)
	@kubectl rollout status deployment/frontend-deployment -n $(NAMESPACE) --timeout=5m

update-image-command:
	@echo "$(BLUE)Updating command service image...$(NC)"
	@kubectl set image deployment/command-deployment \
		springboot-command=thee5176/springboot_cqrs_command:latest \
		-n $(NAMESPACE)
	@kubectl rollout status deployment/command-deployment -n $(NAMESPACE) --timeout=5m

update-image-query:
	@echo "$(BLUE)Updating query service image...$(NC)"
	@kubectl set image deployment/query-deployment \
		springboot-query=thee5176/springboot_cqrs_query:latest \
		-n $(NAMESPACE)
	@kubectl rollout status deployment/query-deployment -n $(NAMESPACE) --timeout=5m

.DEFAULT_GOAL := help
