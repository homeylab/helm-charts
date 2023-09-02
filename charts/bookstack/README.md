# Bookstack
This chart deploys bookstack, an app for self and/or collaborated documentation similar to confluence. This chart includes an option to install mariadb alongside it, enabled by default.

*Note: You should set some chart values by creating your own values.yaml and save that locally*

## Add Chart Repo
```
helm repo add homeylab https://homeylab.github.io/helm-charts/
helm repo update homeylab
```

## Install
```
helm install bookstack homeylab/bookstack -n bookstack --create-namespace

# with own values file - recommended
helm install -f my-values.yaml bookstack homeylab/bookstack -n bookstack --create-namespace
```

## Upgrade
```
helm upgrade bookstack homeylab/bookstack -n bookstack

# with own values file - recommended
helm upgrade -f my-values.yaml bookstack homeylab/bookstack -n bookstack
```

## Prerequisites
Ensure you either enable mariadb dependency, `mariadb.enabled`, or have an existing compatible DB server ready for bookstack. This chart provides the option to install mariadb by default from [bitnami](https://github.com/bitnami/charts/tree/main/bitnami/mariadb).

## Simple Deploy
If you just want to deploy as simple as possible, create your own values.yaml file
1. Uncomment all the key/value variables in `config` section of values.yaml
2. Ensure `mariadb.enabled` is set to true for chart dependency
3. Change APP_URL in config and ingress-nginx (if used) to your preferred hostname
4. Change any relevant persistence options for `persistence.storageClass``

After first install, initial admin account will be set to:
```
email: admin@admin.com
passsword: password
```

## Configuration Options
For more configuration options, refer to the documented env variables available for bookstack [here](https://github.com/BookStackApp/BookStack/blob/development/.env.example.complete)