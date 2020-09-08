.PHONY: lint install test-dev test-staging uninstall cluster-create cluster-delete

VERSION   ?= v1.7.1
K8Z       ?= dev
NAMESPACE ?= ambassador
SHELL     := bash --noprofile --norc -O nullglob -euo pipefail
K8S       ?= $(shell docker inspect k3d-k3d-server-0 | jq -r '.[0].NetworkSettings.Networks["k3d-k3d"].IPAddress')


lint: policy/
	kubectl kustomize $(K8Z) | conftest test --combine -

install: base/resources/ambassador-crds-$(VERSION).yaml
	kubectl apply -f $<
	kubectl create ns $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f-
	kubectl wait --for condition=established --timeout=90s crd -l product=aes
	kubectl apply -k $(K8Z)
	kubectl wait -n $(NAMESPACE) --for condition=available deploy -l app.kubernetes.io/name=ambassador --timeout=10m

test-dev:
	kubectl wait -n $(NAMESPACE) --for condition=ready certificate/k7o-io --timeout=10m
	curl -k --connect-to k7o.io::$(K8S): -fisSL 'k7o.io/cloud?value=<script>'

test-staging: fakelerootx1.pem
	kubectl wait -n $(NAMESPACE) --for condition=ready certificate/k7o-io --timeout=10m
	curl --cacert $< --connect-to k7o.io::$(K8S): -fisSL 'k7o.io/cloud?value=<script>'

uninstall:
	kubectl delete --ignore-not-found -k $(K8Z)
	kubectl delete --ignore-not-found ns $(NAMESPACE)
	kubectl delete --ignore-not-found -f https://raw.githubusercontent.com/datawire/ambassador/$(VERSION)/docs/yaml/ambassador/ambassador-crds.yaml

cluster-create:
	k3d cluster create --no-lb --k3s-server-arg=--no-deploy=traefik --wait --timeout=10m k3d
	kubectl wait deploy --all -n kube-system --for condition=available --timeout=10m

custer-delete:
	k3d cluster delete k3d

policy/:
	conftest pull https://github.com/ctison/conftest/releases/download/v0.0.1/kubernetes.tar.gz

base/resources/ambassador-crds-$(VERSION).yaml:
	curl -Lo $@ https://raw.githubusercontent.com/datawire/ambassador/$(VERSION)/docs/yaml/ambassador/ambassador-crds.yaml

fakelerootx1.pem:
	curl -LO https://letsencrypt.org/certs/fakelerootx1.pem