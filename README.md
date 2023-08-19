# Homeylab Helm Charts

## Add Chart Repo to Use these charts
Add and update
```
helm repo add homeylab https://homeylab.github.io/helm-charts/
helm repo update homeylab
```

Search for apps and versions
```
helm search repo | grep -i homeylab
```

## Chart Collection
A collection of helm charts that I created for some apps that either do not have an existing chart or the chart has grown stale.

For customizations, it is recommended to use your own values file and specify it when using helm with the `-f` flag.

Apps available
| Application  | Description | 
| ------------- | ------------- |
| unpoller  | [unpoller](https://github.com/unpoller/unpoller) gathers metrics from unifi controllers and shows you metrics from your network and devices. |
| bookstack | [bookstack](https://github.com/BookStackApp/BookStack) is an app for self and/or collaborated documentation similar to confluence. This chart includes an option to install mariadb alongside it. |