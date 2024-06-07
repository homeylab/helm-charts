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
IMAGE_TAG=v3.10.1

OCI_REGISTRY=oci://registry-1.docker.io/homeylabcharts

## Replace image in dev

## update dep
update_dep:
	helm dependency update ${CHART_DIR}/$(app)

bookstack_update_dep:
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo update bitnami
	helm dependency update ${CHART_DIR}/$(app) 

## oci
pkg:
	helm package ${CHART_DIR}/$(app)

## includes depedency in `$(app)/charts` directory
pkg_with_dep:
	helm package ${CHART_DIR}/$(app) -u

oci_push:
	helm push $(file) ${OCI_REGISTRY}

## lint
## replace with `ct lint` once we have json schema file
lint:
	helm lint ${CHART_DIR}/$(app)

test:
	ct install --chart-dirs ${CHART_DIR} --charts ${CHART_DIR}/$(app)

test_custom:
	ct install --chart-dirs ${CHART_DIR} --charts ${CHART_DIR}/$(app)

template:
	helm template $(app) ${CHART_DIR}/$(app) --debug

local_template:
	helm template $(app) ${CHART_DIR}/$(app) -f ${LOCAL_VARS_DIR}/$(app).yaml  --debug

dryrun_install_local:
	helm install -f ${LOCAL_VARS_DIR}/$(app).yaml $(app) ${CHART_DIR}/$(app) -n local-$(app) --create-namespace --dry-run

install_local:
	helm install -f ${LOCAL_VARS_DIR}/$(app).yaml $(app) ${CHART_DIR}/$(app) -n local-$(app) --create-namespace

dryrun_upgrade_local:
	helm upgrade -f ${LOCAL_VARS_DIR}/$(app).yaml $(app) ${CHART_DIR}/$(app) -n local-$(app) --dry-run

upgrade_local:
	helm upgrade -f ${LOCAL_VARS_DIR}/$(app).yaml $(app) ${CHART_DIR}/$(app) -n local-$(app)

clean_local:
	helm delete $(app) -n local-$(app)
	kubectl delete ns local-$(app)