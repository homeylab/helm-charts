######## Using this File #########
# call every function with `app=${app}` in order to target the proper chart
# Example: `make lint app=bookstack`

## CT Testing
CHART_DIR=charts

## Local Testing on k3s single cluster
LOCAL_NAMESPACE_SUFFIX=-local
LOCAL_CONTEXT=rancher-desktop
LOCAL_VARS_DIR=local_vars


## lint
## replace with `ct lint` once we have json schema file
lint:
	helm lint ${CHART_DIR}/$(app)

test:
	ct install --chart-dirs ${CHART_DIR} --charts ${CHART_DIR}/$(app)

test_custom:
	ct install --chart-dirs ${CHART_DIR} --charts ${CHART_DIR}/$(app)

install_local:
	helm install -f ${LOCAL_VARS_DIR}/$(app) $(app) -n $(app)-${LOCAL_NAMESPACE} --create-namespace

clean_local:
	helm delete $(app) -n $(app)-${LOCAL_NAMESPACE}
	kubectl delete ns $(app)-${LOCAL_NAMESPACE}