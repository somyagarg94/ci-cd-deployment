APP_NAME=helloservice
CURRENT_WORKING_DIR=$(shell pwd)

# Construct the image tag.
GO_PIPELINE_COUNTER?="unknown"
VERSION=1.1.$(GO_PIPELINE_COUNTER)

# Build configuration.
HOST_GOOS = linux
HOST_GOARCH = amd64
BUILD_ENV = CGO_ENABLED=0
STATIC_FLAGS = -a -installsuffix cgo
TOOLS_DIR := tools

# Glide configuration.
GLIDE_VERSION = v0.13.1
GO_PLATFORM = $(HOST_GOOS)-$(HOST_GOARCH)

# GCLOUD version variable.
GOOGLE_CLOUD_SDK_VERSION=188.0.1

# QUAY.io variables.
QUAY_REPO=somyagarg1994
QUAY_USERNAME=somyagarg1994
QUAY_PASSWORD?="unknown"

# Construct quay image name.
IMAGE = quay.io/$(QUAY_REPO)/$(APP_NAME)

build: build-app build-image clean 

push: docker-login push-image docker-logout

install-gcloud:
	curl -fsSLo google-cloud-sdk.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-$(GOOGLE_CLOUD_SDK_VERSION)-linux-x86_64.tar.gz && \
    tar -xzf google-cloud-sdk.tar.gz && \
    rm google-cloud-sdk.tar.gz && \
    ./google-cloud-sdk/install.sh --quiet && \
    ./google-cloud-sdk/bin/gcloud components install kubectl && \
    rm -rf google-cloud-sdk

install-glide:
	mkdir -p tools
	curl -L https://github.com/Masterminds/glide/releases/download/$(GLIDE_VERSION)/glide-$(GLIDE_VERSION)-$(GO_PLATFORM).tar.gz | tar -xz -C tools

build-helloservice: install-glide
	./$(TOOLS_DIR)/$(GO_PLATFORM)/glide install -v
	go build $(STATIC_FLAGS) -o bin/$(HOST_GOOS)/$(APP_NAME) main.go

build-app:
	docker build -t build-img:$(VERSION) -f Dockerfile.build .

	docker run --name build-image-$(VERSION) \
	--rm -v $(CURRENT_WORKING_DIR):/go/src/github.com/somyagarg94/helloservice:rw \
	build-img:$(VERSION) \
	make build-helloservice

    docker rmi build-img:$(VERSION)
	docker rm -f build-img:$(VERSION)

build-image:
	docker build \
    --build-arg git_repository=`git config --get remote.origin.url` \
    --build-arg git_branch=`git rev-parse --abbrev-ref HEAD` \
    --build-arg git_commit=`git rev-parse HEAD` \
    --build-arg built_on=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
    -t $(IMAGE):$(VERSION) .

docker-login:
	docker login -u $(QUAY_USERNAME) -p $(QUAY_PASSWORD) quay.io

docker-logout:
	docker logout

push-image:
	docker push $(IMAGE):$(VERSION)
	docker rmi $(IMAGE):$(VERSION)

clean:
	rm -rf tools vendor .glide 

run:
	docker-compose up -d

create:
	gcloud init
	gcloud container clusters create helloservice \
    --zone us-east1-c \
    --machine-type n1-standard-1 \
    --num-nodes 2

	curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
	chmod 700 get_helm.sh
	./get_helm.sh
	helm init
	rm -rf get_helm.sh

	kubectl get nodes


deploy:
	helm upgrade --install helloservice helm-chart/helloservice
	kubectl get pods

destroy-cluster:
	gcloud container clusters delete helloservice \
    --zone us-east1-c 