KIND_VERSION=0.4.0
KUDO_VERSION=0.4.0
KUBERNETES_VERSION=1.14.2

GO ?= go
OS=$(shell uname -s | tr '[:upper:]' '[:lower:]')

KUDO_MACHINE=$(shell uname -m)
MACHINE=$(shell uname -m)
ifeq "$(MACHINE)" "x86_64"
  MACHINE=amd64
endif

# Set KUBECONFIG to the kind KUBECONFIG unless USE_KIND=0
ifneq "$(USE_KIND)" "0"
export KUBECONFIG=$(shell bin/kind_$(KIND_VERSION) get kubeconfig-path --name="kind")
endif

bin/:
	mkdir -p bin/

bin/kubectl_$(KUBERNETES_VERSION): bin/
	curl -Lo bin/kubectl_$(KUBERNETES_VERSION) https://storage.googleapis.com/kubernetes-release/release/v$(KUBERNETES_VERSION)/bin/$(OS)/$(MACHINE)/kubectl
	chmod +x bin/kubectl_$(KUBERNETES_VERSION)

bin/kind_$(KIND_VERSION): bin/
	curl -Lo bin/kind_$(KIND_VERSION) https://github.com/kubernetes-sigs/kind/releases/download/v$(KIND_VERSION)/kind-$(OS)-$(MACHINE)
	chmod +x bin/kind_$(KIND_VERSION)

bin/kudoctl_$(KUDO_VERSION): bin/
	curl -Lo bin/kudoctl_$(KUDO_VERSION) https://github.com/kudobuilder/kudo/releases/download/v$(KUDO_VERSION)/kubectl-kudo_$(KUDO_VERSION)_$(OS)_$(KUDO_MACHINE)
	chmod +x bin/kudoctl_$(KUDO_VERSION)

# create a kubernetes-in-docker cluster and replace the standard storage class with the local-path-provisioner.
# fsGroups are not supported in the standard storage class, so we use the rancher local-path-provisioner.
# https://github.com/kubernetes/kubernetes/pull/39438
create-cluster: bin/kind_$(KIND_VERSION) bin/kubectl_$(KUBERNETES_VERSION)
	bin/kind_$(KIND_VERSION) create cluster --image kindest/node:v$(KUBERNETES_VERSION) && \
	export KUBECONFIG=$$(bin/kind_$(KIND_VERSION) get kubeconfig-path --name="kind") && \
	bin/kubectl_$(KUBERNETES_VERSION) delete storageclass standard && \
	bin/kubectl_$(KUBERNETES_VERSION) apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml && \
	bin/kubectl_$(KUBERNETES_VERSION) annotate storageclass --overwrite local-path storageclass.kubernetes.io/is-default-class=true

install-operators: bin/kudoctl_$(KUDO_VERSION) bin/kind_$(KIND_VERSION) bin/kubectl_$(KUBERNETES_VERSION)
	bin/kubectl_$(KUBERNETES_VERSION) apply -f https://raw.githubusercontent.com/kudobuilder/kudo/v${KUDO_VERSION}/docs/deployment/10-crds.yaml
	ls -d repository/*/operator |xargs -n1 bin/kudoctl_$(KUDO_VERSION) install --skip-instance --kubeconfig=$(KUBECONFIG)

# Test runs the test harness using kudoctl test.
test: install-operators
	bin/kudoctl_$(KUDO_VERSION) test
