KUBERNETES_VERSION=1.15.0
KUDO_VERSION=0.5.0

ARTIFACTS ?= artifacts/

OS=$(shell uname -s | tr '[:upper:]' '[:lower:]')

KUDO_MACHINE=$(shell uname -m)
MACHINE=$(shell uname -m)
ifeq "$(MACHINE)" "x86_64"
  MACHINE=amd64
endif

export PATH := $(shell pwd)/bin/:$(PATH)

# Some host configurations cause MySQLd to consume all of the RAM on the system because it thinks it has an exorbitant amonut
# of file descriptors available.
# Before https://github.com/kubernetes-sigs/kind/pull/760 is merged, we need to verify that the tests will not blow up the user's
# host system.
# If they will, bail out and recommend the fix.
.PHONY: verify
verify:
	@if [ "$(shell sysctl -n fs.nr_open)" -gt 104857600 ]; then \
		echo "Very high values of fs.nr_open are known to cause severe system performance issues with certain applications."; \
		echo "Prior to running the tests, please run: sysctl -w fs.nr_open=1048576"; \
		exit 1; \
	fi

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
test: bin/kubectl-kudo_$(KUDO_VERSION) bin/kubectl_$(KUBERNETES_VERSION) verify
	kubectl kudo test --kind-config=test/kind/kubernetes-$(KUBERNETES_VERSION).yaml --artifacts-dir=$(ARTIFACTS)
