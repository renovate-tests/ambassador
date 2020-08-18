NAMESPACE := ambassador
HELM_OPTIONS := -n $(NAMESPACE) --post-renderer ./post-renderer.sh

.PHONY: template dependencies install uninstall
SHELL := bash --noprofile --norc -O nullglob -euo pipefail
GREP_HELM_INFO := 2> >(grep -v 'info: skipping unknown hook: "crd-install"$$')

template:
	helm template $(HELM_OPTIONS) . > out.yaml $(GREP_HELM_INFO)

dependencies:
	helm dep up --skip-refresh

install:
	kubectl create ns ambassador --dry-run=client -o yaml | kubectl apply -f-
	helm upgrade -i $(HELM_OPTIONS) ambassador . $(GREP_HELM_INFO)

uninstall:
	helm uninstall -n $(NAMESPACE)