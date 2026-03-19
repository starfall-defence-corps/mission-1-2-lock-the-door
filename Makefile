SHELL := /bin/bash
ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

.PHONY: setup test reset destroy ssh-web ssh-db ssh-comms help

help: ## Show available commands
	@echo ""
	@echo "=============================================="
	@echo "  STARFALL DEFENCE CORPS ACADEMY"
	@echo "  Mission 1.2: Lock the Door"
	@echo "=============================================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""

setup: ## Start the fleet (3 target nodes)
	@bash $(ROOT_DIR)/scripts/setup-lab.sh

test: ## Ask ARIA to verify your work
	@bash $(ROOT_DIR)/scripts/check-work.sh

reset: ## Destroy and rebuild all fleet nodes
	@bash $(ROOT_DIR)/scripts/reset-lab.sh

destroy: ## Tear down everything (containers, keys, venv)
	@bash $(ROOT_DIR)/scripts/destroy-lab.sh

ssh-web: ## SSH into sdc-web (fleet web server)
	@ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null cadet@localhost -p 2221

ssh-db: ## SSH into sdc-db (fleet database server)
	@ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null cadet@localhost -p 2222

ssh-comms: ## SSH into sdc-comms (fleet comms relay)
	@ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null cadet@localhost -p 2223
