PROJECT_NAME ?= ddf-entrypoint
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
project_home := $(patsubst %/,%,$(dir $(mkfile_path)))
version_file := Version.txt
CACHE_DIR := .cache
BINARY_CACHE := $(CACHE_DIR)/bin
TOOLS_DIR := .tools
ifeq (, $(shell which podman))
	CONTAINER := docker container
else
	CONTAINER := podman container
endif

BATS = $(CONTAINER) run --rm -it --entrypoint=bash -v ./$<:/opt/entrypoint.tar.gz -v ./$@:/tests --workdir /tests docker.io/bats/bats -c "apk add --no-cache bash && mkdir /opt/entrypoint && tar xzf /opt/entrypoint.tar.gz -C /opt/entrypoint && bats *.bats"

ARGBASH := $(TOOLS_DIR)/argbash/bin/argbash

BUILD_DIR := build
BUILD_PACKAGES_DIR := $(BUILD_DIR)/packages
ARGBASH_PREP_DIR := $(BUILD_DIR)/argbash-templates
BUILD_PREP_DIR := $(BUILD_DIR)/prep
VERSION := $(shell cat $(version_file))
PACKAGE_NAME := $(PROJECT_NAME)-$(VERSION)
ARCHIVE_PREP_DIR := $(BUILD_PREP_DIR)/$(PACKAGE_NAME)
ARCHIVE_NAME := $(PACKAGE_NAME).tar.gz
ARCHIVE_OUTPUT := $(BUILD_PACKAGES_DIR)/$(ARCHIVE_NAME)
INSTALL_OUTPUT := $(BUILD_PREP_DIR)/$(PACKAGE_NAME)

PROPS_VERSION := 0.2.0
JQ_VERSION := 1.5
ARGBASH_VERSION := 2.7.1
ENVSUBST_VERSION := 1.1.0
PROPS_DOWNLOAD_URL := https://github.com/oconnormi/props/releases/download/v$(PROPS_VERSION)/props_linux_amd64 
JQ_DOWNLOAD_URL := https://github.com/stedolan/jq/releases/download/jq-$(JQ_VERSION)/jq-linux64
ARGBASH_DOWNLOAD_URL := https://github.com/matejak/argbash/archive/$(ARGBASH_VERSION).tar.gz
ENVSUBST_DOWNLOAD_URL := https://github.com/a8m/envsubst/releases/download/v$(ENVSUBST_VERSION)/envsubst-Linux-x86_64

environment_sources := $(wildcard environment/*.env)
environment_targets := $(patsubst environment/%.env, $(ARCHIVE_PREP_DIR)/environment/%.env, $(environment_sources))
current_environment_source = $(patsubst $(ARCHIVE_PREP_DIR)/environment/%.env, environment/%.env, $@)
library_sources := $(wildcard library/*.sh)
library_targets := $(patsubst library/%.sh, $(ARCHIVE_PREP_DIR)/library/%.sh, $(library_sources))
current_library_source = $(patsubst $(ARCHIVE_PREP_DIR)/library/%.sh, library/%.sh, $@)
argbash_sources := $(wildcard argbash-templates/*.m4)
argbash_targets := $(patsubst argbash-templates/%.m4, $(ARCHIVE_PREP_DIR)/bin/%, $(argbash_sources))
current_argbash_source = $(patsubst $(ARCHIVE_PREP_DIR)/bin/%, argbash-templates/%.m4, $@)
files_sources := $(shell find files -maxdepth 1 -mindepth 1 -type d)
files_targets := $(patsubst files/%, $(ARCHIVE_PREP_DIR)/%, $(files_sources))
current_file_source = $(patsubst $(ARCHIVE_PREP_DIR)/%, files/%, $@)


.DEFAULT_GOAL := help

.PHONY: help
help: ## Display help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: clean
clean: ## Cleans up build artifacts
	@rm -rf $(BUILD_DIR)

.PHONY: clean_cache
clean_cache: ## Cleans up download cache
	@rm -rf $(CACHE_DIR)

.PHONY: build
build: package test ## Build and test the entrypoint

.PHONY: package
package: dependencies prepare $(ARCHIVE_OUTPUT) ## Package the project output into an archive

.PHONY: test
test: argbash-templates/tests tests ## Run Tests

.PHONY: argbash-templates/tests
argbash-templates/tests: $(ARCHIVE_OUTPUT) ## Test Argbash Templates
	$(BATS)

.PHONY: tests
tests: $(ARCHIVE_OUTPUT) ## Run Integration Tests
	$(BATS)

.PHONY: prepare 
prepare: tools $(ARCHIVE_PREP_DIR) $(environment_targets) $(library_targets) $(argbash_targets) $(ARCHIVE_PREP_DIR)/bin/jq $(ARCHIVE_PREP_DIR)/bin/props $(files_targets) ## Prepares for packaging

.PHONY: dependencies
dependencies: $(BINARY_CACHE)/props $(BINARY_CACHE)/jq

.PHONY: tools
tools: $(TOOLS_DIR)/argbash ## Downloads and prepares any tools used by the build

$(CACHE_DIR):
	@mkdir -p $@

$(BINARY_CACHE): $(CACHE_DIR)
	@mkdir -p $@

$(BINARY_CACHE)/props: $(BINARY_CACHE)
	@wget -N -O $@ $(PROPS_DOWNLOAD_URL)
	@touch $@
	@chmod 755 $@

$(BINARY_CACHE)/jq: $(BINARY_CACHE)
	@wget -N -O $@ $(JQ_DOWNLOAD_URL)
	@touch $@
	@chmod 755 $@

$(BINARY_CACHE)/envsubst: $(BINARY_CACHE)
	@wget -N -O $@ $(ENVSUBST_DOWNLOAD_URL)
	@touch $@
	@chmod 755 $@

$(TOOLS_DIR):
	@mkdir -p $@

$(TOOLS_DIR)/argbash: $(CACHE_DIR)/argbash.tar.gz $(TOOLS_DIR)
	@mkdir -p $@
	@tar xzf $< -C $@ --strip-components=1

$(CACHE_DIR)/argbash.tar.gz: $(CACHE_DIR)
	@wget -N -O $@ $(ARGBASH_DOWNLOAD_URL) 
	@touch $@

$(BUILD_DIR):
	@mkdir -p $@

$(BUILD_PREP_DIR): $(BUILD_DIR)
	@mkdir -p $@

$(BUILD_PACKAGES_DIR): $(BUILD_DIR)
	@mkdir -p $@

$(ARCHIVE_PREP_DIR): $(BUILD_PREP_DIR)
	@mkdir -p $@

# Begin Processing sources
# Environment Files
$(ARCHIVE_PREP_DIR)/environment: $(BUILD_PREP_DIR)/$(PACKAGE_NAME)
	@mkdir -p $@

$(environment_targets): %.env: $(ARCHIVE_PREP_DIR)/environment
	@echo "Copying env file: $(current_environment_source) to: $@"
	@cp $(current_environment_source) $@
	@chmod 755 $@

# Library Scripts
$(ARCHIVE_PREP_DIR)/library: $(ARCHIVE_PREP_DIR)
	@mkdir -p $@

$(library_targets): %.sh: $(ARCHIVE_PREP_DIR)/library
	@echo "Copying library file: $(current_library_source) to: $@"
	@cp $(current_library_source) $@
	@chmod 755 $@

# Argbash Scripts
$(ARCHIVE_PREP_DIR)/bin: $(ARCHIVE_PREP_DIR)
	@mkdir -p $@

$(ARGBASH_PREP_DIR): $(BUILD_DIR)
	@mkdir -p $@

$(argbash_targets): %: $(ARCHIVE_PREP_DIR)/bin $(TOOLS_DIR)/argbash
	@echo "Building Argbash Template $(current_argbash_source) as $@"
	@$(ARGBASH) $(current_argbash_source) -o $@
	@touch $@

$(ARCHIVE_PREP_DIR)/bin/jq: $(BINARY_CACHE)/jq $(ARCHIVE_PREP_DIR)/bin
	@echo "Copying jq from $< to $@"
	@cp $< $@
	@chmod 755 $@
	@touch $@

$(files_targets): %: $(ARCHIVE_PREP_DIR)
	@cp -R $(current_file_source) $@

$(ARCHIVE_PREP_DIR)/bin/props: $(BINARY_CACHE)/props $(ARCHIVE_PREP_DIR)/bin
	@echo "Copying props from $< to $@"
	@cp $< $@
	@chmod 755 $@
	@touch $@

$(ARCHIVE_PREP_DIR)/bin/envsubst: $(BINARY_CACHE)/envsubst $(ARCHIVE_PREP_DIR)/bin
	@echo "Copying envsubst from $< to $@"
	@cp $< $@
	@chmod 755 $@
	touch $@

$(ARCHIVE_PREP_DIR)/entrypoint.sh: $(ARCHIVE_PREP_DIR)
	@cp entrypoint.sh $@
	@touch $@
	@chmod 755 $@

$(ARCHIVE_OUTPUT): $(ARCHIVE_PREP_DIR) $(BUILD_PACKAGES_DIR) $(ARCHIVE_PREP_DIR)/bin/props $(ARCHIVE_PREP_DIR)/bin/jq $(ARCHIVE_PREP_DIR)/bin/envsubst $(ARCHIVE_PREP_DIR)/entrypoint.sh $(argbash_targets) $(library_targets) $(environment_targets) $(files_targets)
	@echo "Packaging Entrypoint Distribution $@ from $<"
	@tar czf $@ -C $< .
