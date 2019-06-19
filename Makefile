GO ?= go

export PATH=$(PWD)/bin:$(shell printenv PATH)

# Set KUBECONFIG to the kind KUBECONFIG unless USE_KIND=0
ifneq "$(USE_KIND)" "0"
export KUBECONFIG=$(shell bin/kind get kubeconfig-path --name="kind")
endif

bin/:
	mkdir -p bin/

bin/kubectl: bin/
	curl -Lo bin/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.14.0/bin/linux/amd64/kubectl
	chmod +x bin/kubectl

bin/kind: bin/
	curl -Lo bin/kind https://github.com/kubernetes-sigs/kind/releases/download/v0.3.0/kind-linux-amd64
	chmod +x bin/kind

# create a kubernetes-in-docker cluster and replace the standard storage class with the local-path-provisioner.
# fsGroups are not supported in the standard storage class, so we use the rancher local-path-provisioner.
# https://github.com/kubernetes/kubernetes/pull/39438
create-cluster: bin/kind bin/kubectl
	kind create cluster && \
	export KUBECONFIG=$$(kind get kubeconfig-path --name="kind") && \
	kubectl delete storageclass standard && \
	kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml && \
	kubectl annotate storageclass --overwrite local-path storageclass.kubernetes.io/is-default-class=true

install-frameworks:
	kubectl apply -f https://raw.githubusercontent.com/kudobuilder/kudo/master/docs/deployment/10-crds.yaml
	ls -d repository/*/0.*/*.yaml |grep -v instance |xargs -n1 kubectl apply -f

# Test runs the test framework using go test.
# GOPROXY makes it fetch dependencies faster.
test: install-frameworks
	GOPROXY=https://proxy.golang.org GO111MODULE=on $(GO) test -v -count=8 ./
