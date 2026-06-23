# Build container images locally using Podman

# Default registry and namespace
REGISTRY ?= quay.io
NAMESPACE ?= agentfox

# Image names and tags
OPENCODE_IMAGE = $(REGISTRY)/$(NAMESPACE)/opencode
TAG ?= latest

# Build tool
CONTAINER_TOOL ?= podman

# Build arguments
BUILD_ARGS ?= --build-arg TARGETARCH=$(shell uname -m | sed 's/x86_64/x64/;s/aarch64/arm64/')

.PHONY: help all build-all opencode clean clean-all push-all

# Build the opencode image
opencode:
	@echo "🔨 Building opencode image..."
	$(CONTAINER_TOOL) build $(BUILD_ARGS) \
		-f containers/opencode/Containerfile \
		-t $(OPENCODE_IMAGE):$(TAG) \
		.
	@echo "✅ Opencode image built: $(OPENCODE_IMAGE):$(TAG)"

# run the opencode image
run:
	@echo "🔨 Running opencode image..."
	source .env && \
	$(CONTAINER_TOOL) run -d \
		--name opencode \
		-p 4096:4096 \
		-v ./data/data:/opt/app-root/data \
		-v ./data/state:/opt/app-root/state \
		-v ./data/config:/opt/app-root/config \
		-v ./data/cache:/opt/app-root/cache \
		-e TZ="${TZ}" \
		-e OPENCODE_SERVER_USERNAME="${OPENCODE_SERVER_USERNAME}" \
		-e OPENCODE_SERVER_PASSWORD="${OPENCODE_SERVER_PASSWORD}" \
		$(OPENCODE_IMAGE):$(TAG)
	@echo "✅ Opencode image running"

# Clean up any configuration files
clean-config:
	@echo "🧹 Cleaning up configuration files..."
	rm -rf data/data data/state data/config data/cache
	@echo "✅ Configuration files cleaned"

create-config:
	@echo "🧹 Creating configuration files..."
	mkdir -p data/data/opencode data/state data/config/opencode data/cache
	cp hack/auth.json ./data/data/opencode/auth.json
	cp hack/opencode.jsonc ./data/config/opencode/opencode.jsonc
	@echo "✅ Configuration files created"

# Clean up locally built images
clean-images:
	@echo "🧹 Cleaning up locally built images..."
	-$(CONTAINER_TOOL) rmi $(OPENCODE_IMAGE):$(TAG) 2>/dev/null || true
	@echo "✅ Local images cleaned"

# Clean up all related images including base images and any configuration files
clean-all: clean-config clean-images
	@echo "🧹 Cleaning up all related images..."
	-$(CONTAINER_TOOL) system prune -f 2>/dev/null || true
	@echo "✅ All images cleaned"

