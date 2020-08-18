VERSION ?= 1.6.2
K8Z ?= dev/
SHELL := bash --noprofile --norc -O nullglob -euo pipefail

install:
	kubectl apply -f https://raw.githubusercontent.com/datawire/ambassador/v$(VERSION)/docs/yaml/ambassador/ambassador-crds.yaml
	kubectl create ns ambassador --dry-run=client -o yaml | kubectl apply -f-
	kubectl wait --for condition=established --timeout=90s crd -lproduct=aes
	kubectl kustomize $(K8Z) > /dev/null
	kubectl apply -k $(K8Z)

uninstall:
	kubectl delete --ignore-not-found ns ambassador
	kubectl delete --ignore-not-found -f https://raw.githubusercontent.com/datawire/ambassador/v$(VERSION)/docs/yaml/ambassador/ambassador-crds.yaml