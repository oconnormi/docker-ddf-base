# Set the base name for the image
IMAGE_NAME:=codice/ddf-base

GIT_SHA:=$(shell git rev-parse HEAD)
MASTER_SHA:=$(shell git show-ref -s refs/heads/master)
ifneq (${MASTER_SHA}, ${GIT_SHA})
	IMAGE_VERSION=${GIT_SHA}
else
	IMAGE_VERSION=latest
endif
# Compute Build Tag
BUILD_TAG=$(IMAGE_NAME):$(IMAGE_VERSION)

.DEFAULT_GOAL := help

.PHONY: help
help: ## Display help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: image
image: ## Build the docker image
	@echo "Building $(BUILD_TAG)"
	@docker build --pull -t $(BUILD_TAG) .

.PHONY: push
push: image ## Push the docker image
	@echo "Pushing $(BUILD_TAG)"
	@docker push $(BUILD_TAG)

