.PHONY: lint install test uninstall

VERSION   ?= v1.6.2
K8Z       ?= dev
NAMESPACE ?= ambassador
SHELL     := bash --noprofile --norc -O nullglob -euo pipefail

lint: policy/
	kubectl kustomize $(K8Z) | conftest test --combine -

install: base/resources/ambassador-crds-$(VERSION).yaml
	kubectl apply -f $<
	kubectl create ns $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f-
	kubectl wait --for condition=established --timeout=90s crd -l product=aes
	kubectl apply -k $(K8Z)
	kubectl wait -n $(NAMESPACE) --for condition=available --timeout=5m deploy -l app.kubernetes.io/name=ambassador

test:
	curl -k --connect-to example.com::k3d-lol-server-0: -Li example.com/lol

uninstall:
	kubectl delete -k $(K8Z)
	kubectl delete --ignore-not-found ns $(NAMESPACE)
	kubectl delete --ignore-not-found -f https://raw.githubusercontent.com/datawire/ambassador/$(VERSION)/docs/yaml/ambassador/ambassador-crds.yaml

policy/:
	conftest pull https://github.com/ctison/conftest/releases/download/v0.0.1/kubernetes.tar.gz

base/resources/ambassador-crds-$(VERSION).yaml:
	curl -Lo $@ https://raw.githubusercontent.com/datawire/ambassador/$(VERSION)/docs/yaml/ambassador/ambassador-crds.yaml
