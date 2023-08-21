# Unpoller
This chart deploys unpoller, an app that gathers metrics from unifi controllers and formats it for prometheus scraping or service monitors.

*Note: You should set some chart values by creating your own values.yaml and save that locally*

## Add Chart Repo
```
helm repo add homeylab https://homeylab.github.io/helm-charts/
helm repo update homeylab
```

## Install
```
helm install unpoller homeylab/unpoller -n unpoller --create-namespace

# with own values file - recommended
helm install -f my-values.yaml homeylab/unpoller -n unpoller --create-namespace
```

## Upgrade
```
helm upgrade unpoller homeylab/unpoller -n unpoller

# with own values file - recommended
helm upgrade -f my-values.yaml unpoller homeylab/unpoller -n unpoller
```

## Prerequisites
Ensure you have created a user in your unifi site as described here: https://unpoller.com/docs/install/controllerlogin

## Simple Deploy
If you just want to deploy as simple as possible, create your own values.yaml file
1. uncomment all the key/value variables in `config` section of values.yaml
2. update the 3 variables below in config section with your values
```
config:
    ...
    UP_UNIFI_CONTROLLER_0_USER: {{ your_created_user/email }}
    UP_UNIFI_CONTROLLER_0_PASS: {{ your_created_user_pass }}
    UP_UNIFI_CONTROLLER_0_URL: {{ your_unifi_url }}
```
* A note on email vs user:
    - For a Non UnifiOS Controller (like: https://hub.docker.com/r/linuxserver/unifi-controller), email field will be the 'username'.

Then deploy:
```
helm install -f my-values.yaml unpoller unpoller/ -n unpoller --create-namespace
```

## Configuration Options
I will try to explain some of the options and what they do since the wording on the docs may be confusing for some.

The default config options provided in this chart match the same values given in the dockercompose example from unpoller.

### Important Options
1. `UP_PROMETHEUS_NAMESPACE`
    * By default, the image is going to use the value of UP_PROMETHEUS_NAMESPACE ( not your actual deployed namespace) to prepend the metrics
    * example: "{{ namespace }}_client_receive_bytes_total" => "unpoller_client_receive_bytes_total"
    * Since the grafana charts (https://github.com/unpoller/dashboards) all have `unpoller` set in the prom queries, you should put this as `unpoller`
    * To clarify: You can install this helm chart in any namespace you'd like though, just keep it the above env variable equal to "unpoller" for metrics
    * This info is still accurate at the time of writing

2. `UP_UNIFI_CONTROLLER_0_USER`
    * As mentioned earlier:
        * For a Non UnifiOS Controller (like: https://hub.docker.com/r/linuxserver/unifi-controller), use the email field as the username.
        * For Cloud Key, should be the actual username

3. `UP_UNIFI_CONTROLLER_0_SAVE_DPI`
    * This is set to `enabled` by default and requires DPI (Deep Packet Inspection) to be enabled for your site in Unifi
    * If not `enabled`, you will see no data

### References
* https://unpoller.com/docs/install/configuration/
* https://unpoller.com/docs/install/dockercompose