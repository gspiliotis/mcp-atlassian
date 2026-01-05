.PHONY: help init plan apply destroy fmt validate clean outputs

# Default target
.DEFAULT_GOAL := help

# Variables
TF_VARS_FILE := terraform.tfvars

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Initialize Terraform
	terraform init

plan: ## Show Terraform execution plan
	@if [ ! -f $(TF_VARS_FILE) ]; then \
		echo "Error: $(TF_VARS_FILE) not found. Copy terraform.tfvars.example to terraform.tfvars and customize it."; \
		exit 1; \
	fi
	terraform plan -var-file=$(TF_VARS_FILE)

apply: ## Apply Terraform configuration
	@if [ ! -f $(TF_VARS_FILE) ]; then \
		echo "Error: $(TF_VARS_FILE) not found. Copy terraform.tfvars.example to terraform.tfvars and customize it."; \
		exit 1; \
	fi
	terraform apply -var-file=$(TF_VARS_FILE)

destroy: ## Destroy Terraform-managed infrastructure
	@echo "WARNING: This will destroy all resources!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		terraform destroy -var-file=$(TF_VARS_FILE); \
	fi

fmt: ## Format Terraform files
	terraform fmt -recursive

validate: ## Validate Terraform configuration
	terraform validate

clean: ## Clean up Terraform files
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate*
	rm -f crash.log

outputs: ## Show Terraform outputs
	terraform output

output-endpoint: ## Show service endpoint
	@terraform output -raw service_endpoint

output-vpc-endpoint: ## Show VPC endpoint service name
	@terraform output -raw vpc_endpoint_service_name

logs: ## Tail CloudWatch logs
	@LOG_GROUP=$$(terraform output -raw cloudwatch_log_group_name 2>/dev/null); \
	if [ -z "$$LOG_GROUP" ]; then \
		echo "Error: Could not get log group name. Has infrastructure been deployed?"; \
		exit 1; \
	fi; \
	aws logs tail $$LOG_GROUP --follow

ecs-tasks: ## List running ECS tasks
	@CLUSTER=$$(terraform output -raw ecs_cluster_name 2>/dev/null); \
	if [ -z "$$CLUSTER" ]; then \
		echo "Error: Could not get cluster name. Has infrastructure been deployed?"; \
		exit 1; \
	fi; \
	aws ecs list-tasks --cluster $$CLUSTER

ecs-exec: ## Connect to ECS task via exec (requires task ARN)
	@CLUSTER=$$(terraform output -raw ecs_cluster_name 2>/dev/null); \
	if [ -z "$$CLUSTER" ]; then \
		echo "Error: Could not get cluster name. Has infrastructure been deployed?"; \
		exit 1; \
	fi; \
	read -p "Enter task ARN: " TASK_ARN; \
	aws ecs execute-command \
		--cluster $$CLUSTER \
		--task $$TASK_ARN \
		--container mcp-atlassian \
		--interactive \
		--command "/bin/sh"

setup: ## Initial setup (create tfvars from example)
	@if [ -f $(TF_VARS_FILE) ]; then \
		echo "Warning: $(TF_VARS_FILE) already exists. Not overwriting."; \
	else \
		cp terraform.tfvars.example $(TF_VARS_FILE); \
		echo "Created $(TF_VARS_FILE) from example. Please edit it with your values."; \
	fi
