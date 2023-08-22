# Homeylab Helm Charts

## Add Chart Repo to Use these charts
```
helm repo add homeylab https://homeylab.github.io/helm-charts/
helm repo update homeylab
```

## Search For Apps and Versions
```
helm search repo homeylab
```

## Chart Collection
A collection of helm charts that I created for some apps that either do not have an existing chart or the chart has grown stale.

For customizations, it is recommended to use your own values file and specify it when using helm with the `-f` flag. See Recommendations section below for more details.

Apps available
| Application  | Description | 
| ------------- | ------------- |
| unpoller  | [unpoller](https://github.com/unpoller/unpoller) gathers metrics from unifi controllers and shows you metrics from your network and devices. |
| bookstack | [bookstack](https://github.com/BookStackApp/BookStack) is an app for self and/or collaborated documentation similar to confluence. This chart includes an option to install mariadb alongside it. |

## Recommendations
### Create A Values File
Use a values file to make changes and save your custom configuration. When using upstream helm charts and specifying your own values file, variables are handled like so:

- First the base default values.yaml in the project/bundle is evaluated and all variables and values loaded.
- When you specify your own file, your configuration is applied on top and overrides existing configuration in the base values.yaml. Certain variable types will be merged with your changes instead of overriden, for example: `config:{}` would be merged.

General recommendation is only specify in your own values file what you are customizing or overriding. You can also include variables that are defaulted to a specific value that you need to stay constant, just in case the upstream helm chart changes. For example, maybe you are using a protocol like TCP and that is default now, it may change to UDP in the future, so you might want to keep that in your own values file. This allows you to keep your files minimal and easy to upgrade when values change since your scope is smaller.

Use the `-f` flag like so, example
```
helm install -f my-values.yaml unpoller homeylab/unpoller -n unpoller --create-namespace
```

### Use Versioning
Use chart versioning when installing/upgrading charts. This can help prevent unexpected changes/issues from occuring if the upstream chart has been updated in a breaking manner. Example
```
# Get version to install
helm search repo homeylab/unpoller
NAME             	CHART VERSION	APP VERSION	DESCRIPTION
homeylab/unpoller	1.0.0        	2.8.1      	A Helm chart for Kubernetes

# Install a specific version
helm install -f my-values.yaml unpoller homeylab/unpoller -n unpoller --create-namespace --version 1.0.0
```

## Tested On
All charts are currently tested on:
- k3s `v1.27.4`
- Helm `v3.12.1`