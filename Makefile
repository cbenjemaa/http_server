.PHONY: init check plan clean apply deploy destroy
.SILENT: check

SHELL:=/bin/bash

CWD = $(CURDIR)
TF_DIR ?= $(CWD)/deploy
TERRAFORM ?= terraform
PLAN ?= ${PWD}/build/output.tfplan
API_SERVER_STATUS ?= $(shell minikube status --format='{{.APIServer}}')
KUBELET_STATUS ?= $(shell minikube status --format='{{.Kubelet}}')
MINIKUBE_HOST_STATUS ?= $(shell minikube status --format='{{.Host}}')
HTTP_SERVER_URL?=$(shell minikube service --url http-server)
# If docker version returns Server section, it means that
# docker engine is running
DOCKER_ENGINE_STATUS?=$(shell docker version | grep Server)

clean:
	rm -rf $(TF_DIR)/.terraform

init: | clean check
	cd '$(TF_DIR)' && \
	  $(TERRAFORM) init

plan: | check-image-tag check init
	cd '$(TF_DIR)' && \
	$(TERRAFORM) plan -var 'http-server-version=$(IMAGE_TAG)' -out $(PLAN)

apply: | check-image-tag plan
	cd '$(TF_DIR)' && \
	$(TERRAFORM) apply $(PLAN)

destroy: | init
	cd '$(TF_DIR)' && \
	$(TERRAFORM) destroy -var 'http-server-version=$(IMAGE_TAG)'

list: | check init
	$(TERRAFORM) state list

output:
	$(TERRAFORM) output -json

get-http-server-url:
	echo $(shell minikube service --url http-server)

deploy: | load-image apply get-http-server-url

check: | check-minikube check-docker

check-image-tag:
ifeq ($(IMAGE_TAG),)
	printf '%s\n%s %s\n' 'Pass IMAGE_TAG variable as argument:' \
	  'make <make target> IMAGE_TAG="<docker-image-version>"'
	exit 1
endif

build-image: | check-image-tag check-docker
	docker build -t http-server:$(IMAGE_TAG) .

# Load the Docker image to minikube
load-image: | check-image-tag check-minikube build-image
	minikube image load http-server:$(IMAGE_TAG)

check-docker:
ifeq ($(DOCKER_ENGINE_STATUS),)
	echo "- Docker Engine doesn't seem to be running"
	exit 1
endif

check-minikube:
ifneq "$(MINIKUBE_HOST_STATUS)" "Running"
	echo '- Minikube host is not Running try to run "minikube start"'
	exit 1
endif
ifneq "$(API_SERVER_STATUS)" "Running"
	echo '- Minikube host is not Running try to run "minikube start" or troubleshoot your minikube setup'
	exit 1
endif
ifneq "$(KUBELET_STATUS)" "Running"
	echo '- Kubelet is not Running try to run "minikube start" or troubleshoot your minikube setup'
	exit 1
endif