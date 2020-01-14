KUBERNETES_VERSION=1.15.0
KUDO_VERSION=0.10.0

ARTIFACTS ?= artifacts/

OS=$(shell uname -s | tr '[:upper:]' '[:lower:]')

KUDO_MACHINE=$(shell uname -m)
MACHINE=$(shell uname -m)
ifeq "$(MACHINE)" "x86_64"
  MACHINE=amd64
endif

export PATH := $(shell pwd)/bin/:$(PATH)

bin/:
	mkdir -p bin/

bin/kubectl_$(KUBERNETES_VERSION): bin/
	curl -Lo bin/kubectl_$(KUBERNETES_VERSION) https://storage.googleapis.com/kubernetes-release/release/v$(KUBERNETES_VERSION)/bin/$(OS)/$(MACHINE)/kubectl
	chmod +x bin/kubectl_$(KUBERNETES_VERSION)
	ln -sf ./kubectl_$(KUBERNETES_VERSION) ./bin/kubectl

bin/kubectl-kudo_$(KUDO_VERSION): bin/
	curl -Lo bin/kubectl-kudo_$(KUDO_VERSION) https://github.com/kudobuilder/kudo/releases/download/v$(KUDO_VERSION)/kubectl-kudo_$(KUDO_VERSION)_$(OS)_$(KUDO_MACHINE)
	chmod +x bin/kubectl-kudo_$(KUDO_VERSION)
	ln -sf ./kubectl-kudo_$(KUDO_VERSION) ./bin/kubectl-kudo

.PHONY: create-cluster
create-cluster:
	echo

.PHONY: test
# Test runs the test harness using kubectl-kudo test.
test: bin/kubectl-kudo_$(KUDO_VERSION) bin/kubectl_$(KUBERNETES_VERSION)
	kubectl kudo test --kind-config=test/kind/kubernetes-$(KUBERNETES_VERSION).yaml --artifacts-dir=$(ARTIFACTS)

.PHONY: clean
# cleans project
clean:
	./clean-build.sh

.PHONY: index
# builds repo index
index: bin/kubectl-kudo_$(KUDO_VERSION)
	./build-community-repo.sh
