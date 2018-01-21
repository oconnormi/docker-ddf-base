# Set the base name for the image
IMAGE_NAME:=oconnormi/ddf-base
# Get current system arch, used when building tags
IMAGE_ARCH:=$(shell uname -m | sed 's/x86_64/amd64/')
# manifest-tool download variables
MANIFEST_TOOL_ARCH:=$(shell uname -m | sed 's/x86_64/amd64/')
MANIFEST_TOOL_OS:=$(shell uname -s | awk '{print tolower($0)}')
MANIFEST_TOOL_VERSION:=0.7.0
MANIFEST_TOOL_NAME=manifest-tool-$(MANIFEST_TOOL_OS)-$(MANIFEST_TOOL_ARCH)
MANIFEST_TOOL_URL=https://github.com/estesp/manifest-tool/releases/download/v$(MANIFEST_TOOL_VERSION)/$(MANIFEST_TOOL_NAME)

# Find all Dockerfiles, excluding windows. then strip linux and Dockerfile from resulting path
# this will help to make friendly build targets like $image_version/$image_os
BUILDS:=$(sort $(shell find -L . -type f -name Dockerfile | grep -v "windows" | sed 's:linux/::' | sed 's:/Dockerfile::' | sed 's:\./::'))
# Append 'push_' to each build in the $(BUILDS) list in order to create a list for each push target
PUSH_TARGETS:=$(shell echo "$(BUILDS)" | sed 's/[^ ]* */push_&/g')
# Remove everything after the first '/' and remove any 'push_' prefix in order to find the version number
VERSION=$(shell echo $@ | sed 's:/.*::' | sed 's/push_//' | sed 's/manifest_//')
# Compute docker build context based on the version
DOCKER_BUILD_CONTEXT=$(VERSION)/linux
# Remove everything before the including and before the first '/' in order to find the container's OS
OS=$(shell echo $@ | sed 's:.*/::')
# Compute Dockerfile path
DOCKERFILE_PATH=$(DOCKER_BUILD_CONTEXT)/$(OS)/Dockerfile
# Compute Build Tag
BUILD_TAG=$(IMAGE_NAME):$(VERSION)-$(OS)-$(IMAGE_ARCH)
# manifest-tool input variables
MANIFEST_TARGETS:=$(shell echo "$(BUILDS)" | sed 's/[^ ]* */manifest_&/g')
MANIFEST_PLATFORMS:=linux/amd64
MANIFEST_TEMPLATE=$(IMAGE_NAME):$(VERSION)-$(OS)-ARCH
MANIFEST_NAME=$(IMAGE_NAME):$(VERSION)-$(OS)

.DEFAULT_GOAL := help

.PHONY: help
help: ## Display help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: build
build: $(BUILDS) ## Build all docker containers

.PHONY: $(BUILDS)
$(BUILDS): ## Build specific image
	@echo "Building $(BUILD_TAG)"
	@docker build -t $(BUILD_TAG) -f $(DOCKERFILE_PATH) $(DOCKER_BUILD_CONTEXT)

.PHONY: push
push: build $(PUSH_TARGETS) ## Push all images

.PHONY: $(PUSH_TARGETS)
$(PUSH_TARGETS): ## Push specific image
	@echo "Pushing $(BUILD_TAG)"
	@docker push $(BUILD_TAG)

.PHONY: manifests
manifests: $(MANIFEST_TARGETS) ## Create all manifests

.PHONY: $(MANIFEST_TARGETS)
$(MANIFEST_TARGETS): .tools/manifest-tool ## Push manifest objects
	@echo "Creating/Pushing manifest object for $(MANIFEST_NAME)"
	@.tools/manifest-tool push from-args \
		--platforms $(MANIFEST_PLATFORMS) \
		--template $(MANIFEST_TEMPLATE) \
		--target $(MANIFEST_NAME)

.tools/manifest-tool: ## Install manifest-tool
	@echo "Downloading manifest-tool $(MANIFEST_TOOL_NAME)"
	@mkdir -p ./.tools
	@curl -o .tools/manifest-tool -LsSk $(MANIFEST_TOOL_URL)
	@chmod 755 .tools/manifest-tool
