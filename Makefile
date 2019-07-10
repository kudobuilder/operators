KIND_VERSION=0.4.0
KUDO_VERSION=0.3.1
KUBERNETES_VERSION=1.14.2

GO ?= go
OS=$(shell uname -s | tr '[:upper:]' '[:lower:]')

KUDO_MACHINE=$(shell uname -m)
MACHINE=$(shell uname -m)
ifeq "$(MACHINE)" "x86_64"
  MACHINE=amd64
endif

export PATH=$(PWD)/bin:$(shell printenv PATH)

# Set KUBECONFIG to the kind KUBECONFIG unless USE_KIND=0
ifneq "$(USE_KIND)" "0"
export KUBECONFIG=$(shell bin/kind get kubeconfig-path --name="kind")
endif

bin/:
	mkdir -p bin/

bin/kubectl: bin/
	curl -Lo bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v$(KUBERNETES_VERSION)/bin/$(OS)/$(MACHINE)/kubectl
	chmod +x bin/kubectl

bin/kind: bin/
	curl -Lo bin/kind https://github.com/kubernetes-sigs/kind/releases/download/v$(KIND_VERSION)/kind-$(OS)-$(MACHINE)
	chmod +x bin/kind

bin/kudoctl: bin/
	curl -Lo bin/kudoctl https://github.com/kudobuilder/kudo/releases/download/v$(KUDO_VERSION)/kubectl-kudo_$(KUDO_VERSION)_$(OS)_$(KUDO_MACHINE)
	chmod +x bin/kudoctl

# create a kubernetes-in-docker cluster and replace the standard storage class with the local-path-provisioner.
# fsGroups are not supported in the standard storage class, so we use the rancher local-path-provisioner.
# https://github.com/kubernetes/kubernetes/pull/39438
create-cluster: bin/kind bin/kubectl bin/kudoctl
	kind create cluster --image kindest/node:v$(KUBERNETES_VERSION) && \
	export KUBECONFIG=$$(kind get kubeconfig-path --name="kind") && \
	kubectl delete storageclass standard && \
	kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml && \
	kubectl annotate storageclass --overwrite local-path storageclass.kubernetes.io/is-default-class=true

install-operators:
	kubectl apply -f https://raw.githubusercontent.com/kudobuilder/kudo/master/docs/deployment/10-crds.yaml
	ls -d repository/*/operator |xargs -n1 kudoctl install --skip-instance --kubeconfig=$(KUBECONFIG)

# Test runs the test harness using kudoctl test.
test: install-operators
	kudoctl test
