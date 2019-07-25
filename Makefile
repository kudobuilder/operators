KIND_VERSION=0.4.0
KUBERNETES_VERSION=1.14.2

GO ?= go
OS=$(shell uname -s | tr '[:upper:]' '[:lower:]')

MACHINE=$(shell uname -m)
ifeq "$(MACHINE)" "x86_64"
  MACHINE=amd64
endif

# Set KUBECONFIG to the kind KUBECONFIG unless USE_KIND=0
ifneq "$(USE_KIND)" "0"
export KUBECONFIG=$(shell bin/kind_$(KIND_VERSION) get kubeconfig-path --name="kind")
endif

export GO111MODULE=on

KUDOCTL=$(GO) run github.com/kudobuilder/kudo/cmd/kubectl-kudo

bin/:
	mkdir -p bin/

bin/kubectl_$(KUBERNETES_VERSION): bin/
	curl -Lo bin/kubectl_$(KUBERNETES_VERSION) https://storage.googleapis.com/kubernetes-release/release/v$(KUBERNETES_VERSION)/bin/$(OS)/$(MACHINE)/kubectl
	chmod +x bin/kubectl_$(KUBERNETES_VERSION)

bin/kind_$(KIND_VERSION): bin/
	curl -Lo bin/kind_$(KIND_VERSION) https://github.com/kubernetes-sigs/kind/releases/download/v$(KIND_VERSION)/kind-$(OS)-$(MACHINE)
	chmod +x bin/kind_$(KIND_VERSION)

create-cluster: bin/kind_$(KIND_VERSION) bin/kubectl_$(KUBERNETES_VERSION)
	bin/kind_$(KIND_VERSION) create cluster --image kindest/node:v$(KUBERNETES_VERSION)

install-operators: bin/kind_$(KIND_VERSION) bin/kubectl_$(KUBERNETES_VERSION)
	bin/kubectl_$(KUBERNETES_VERSION) apply -f https://raw.githubusercontent.com/kudobuilder/kudo/master/docs/deployment/10-crds.yaml
	ls -d repository/*/operator |xargs -n1 $(KUDOCTL) install --skip-instance --kubeconfig=$(KUBECONFIG)

# Test runs the test harness using kudoctl test.
test: install-operators
	$(KUDOCTL) test
