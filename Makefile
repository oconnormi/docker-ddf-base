PROJECT_NAME ?= "ddf-entrypoint"
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
project_home := $(patsubst %/,%,$(dir $(mkfile_path)))
version_file := $(project_home)/Version.txt
CACHE_DIR ?= $(project_home)/.cache
BINARY_CACHE := $(CACHE_DIR)/bin

BUILD_DIR ?= $(project_home)/build
BUILD_PACKAGES_DIR := $(BUILD_DIR)/packages
BUILD_PREP_DIR := $(BUILD_DIR)/prep
VERSION := $(shell cat $(version_file))
PACKAGE_NAME := $(PROJECT_NAME)-$(VERSION)
ARCHIVE_NAME := $(PACKAGE_NAME).tar.gz
ARCHIVE_OUTPUT := $(BUILD_PACKAGES_DIR)/$(ARCHIVE_NAME)
INSTALL_OUTPUT := $(BUILD_PREP_DIR)/$(PACKAGE_NAME)

.DEFAULT_GOAL := help

.PHONY: help
help: ## Display help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: package
package: dependencies prepare ## Package the project output into an archive
	@echo "Building..."

.PHONY: prepare
prepare: $(BUILD_PREP_DIR)/$(PACKAGE_NAME) ## Prepares for packaging
	@echo "Preparing..."

.PHONY: dependencies
dependencies: $(BINARY_CACHE)/props $(BINARY_CACHE)/jq
	@echo "Downloading Dependencies"

$(CACHE_DIR):
	@mkdir -p $@

$(BINARY_CACHE): $(CACHE_DIR)
	@mkdir -p $@

$(BINARY_CACHE)/props: $(BINARY_CACHE)
	@wget -N -O $@ https://github.com/oconnormi/props/releases/download/v0.2.0/props_linux_amd64
	@touch $@
	@chmod 755 $@

$(BINARY_CACHE)/jq: $(BINARY_CACHE)
	@wget -N -O $@ https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 
	@touch $@
	@chmod 755 $@

$(BUILD_DIR):
	@mkdir -p $@

$(BUILD_PREP_DIR): $(BUILD_DIR)
	@mkdir -p $@

$(BUILD_PACKAGES_DIR): $(BUILD_DIR)
	@mkdir -p $@

$(BUILD_PREP_DIR)/$(PACKAGE_NAME): $(BUILD_PREP_DIR)
	@mkdir -p $@
