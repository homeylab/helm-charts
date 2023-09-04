######## Using this File #########
# call every function with `app=${app}` in order to target the proper chart
# Example: `make lint app=bookstack`

## CT Testing
CHART_DIR=charts

## Local Testing on k3s single cluster
# LOCAL_NAMESPACE_PREFIX=local-
LOCAL_CONTEXT=rancher-desktop
LOCAL_VARS_DIR=local_vars

## Docker image for dev containers
IMAGE_REPO=quay.io/helmpack/chart-testing
IMAGE_TAG=v3.9.0

## Replace image in dev

## lint
## replace with `ct lint` once we have json schema file
lint:
	helm lint ${CHART_DIR}/$(app)

test:
	ct install --chart-dirs ${CHART_DIR} --charts ${CHART_DIR}/$(app)

test_custom:
	ct install --chart-dirs ${CHART_DIR} --charts ${CHART_DIR}/$(app)

dryrun_install_local:
	helm install $(app) ${CHART_DIR}/$(app) -n local-$(app) --create-namespace --dry-run

install_local:
	helm install $(app) ${CHART_DIR}/$(app) -n local-$(app) --create-namespace

clean_local:
	helm delete $(app) -n $(app)-${LOCAL_NAMESPACE}
	kubectl delete ns $(app)-${LOCAL_NAMESPACE}