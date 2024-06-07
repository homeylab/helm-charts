# V Rising Dedicated Server
![Version: 0.0.1](https://img.shields.io/badge/Version-0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.1](https://img.shields.io/badge/AppVersion-2.1-informational?style=flat-square)

Table of Contents
- [V Rising Dedicated Server](#v-rising-dedicated-server)
  - [Add Chart Repo](#add-chart-repo)
  - [Install](#install)
  - [Upgrade](#upgrade)
  - [Configuration Options](#configuration-options)

A Helm chart to deploy a V Rising dedicated server [image](https://github.com/TrueOsiris/docker-vrising).

> **Note** - the upstream image used has limited ability to modify the server settings. Some settings are set in the image and can only be modified by editing the settings file in the persistent volume or copying one onto the volume/container.<br/><br/>
For more information on how to change default settings, see the upstream documentation [here](https://github.com/TrueOsiris/docker-vrising?tab=readme-ov-file#remarks).<br/><br/>
To edit the world/server setting files, you can do a `kubectl exec -it {container-name} bash` or copy directly: `kubectl cp {local-file} {namespace}/{pod-name}:{container-path}`. The pod should be restarted after manual edits are made.

If there is a more suitable image available, please open an issue or PR to discuss!

## Add Chart Repo
```bash
helm repo add homeylab https://homeylab.github.io/helm-charts/
# update the chart, this can also be run to pull new versions of the chart for upgrades
helm repo update homeylab
```

## Install
```bash
helm install v-rising homeylab/v-rising -n v-rising --create-namespace

# with own values file - recommended
helm install -f my-values.yaml v-rising homeylab/v-rising -n v-rising --create-namespace
```

#### OCI Registry Support
```bash
helm install v-rising -n v-rising oci://registry-1.docker.io/homeylabcharts/v-rising --version X.Y.Z --create-namespace

# with own values file - recommended
helm install -f my-values.yaml v-rising -n v-rising oci://registry-1.docker.io/homeylabcharts/v-rising --version X.Y.Z --create-namespace
```

### Install Example
Only some options are shown, view `values.yaml` for an exhaustive list. You can add/change more properties as needed.

Click below to expand for an example of a valid `custom-values.yaml` file. 
<details closed>
<summary>custom-values.yaml</summary>
<br>

```yaml
# custom-values.yaml
service:
  server:
    type: LoadBalancer
    loadBalancerIP: 10.0.50.250

config:
  # -- name of server
  serverName: "v-rising-helm"
  # -- name of world
  worldName: "v-rising-helm-world"
  # -- optional lifetime of logfiles
  logDays: 5

persistence:
  steamServer:
    # -- enable persistence using PVC for dedicated server files
    enabled: true
  world:
    # -- enable persistence using PVC for world files
    enabled: true
```
</details>
<br>

Install with custom:
```bash
helm install -f custom-values.yaml v-rising homeylab/v-rising -n v-rising --create-namespace
```

## Upgrade
```bash
helm upgrade v-rising homeylab/v-rising -n v-rising

# with own values file - recommended
helm upgrade -f my-values.yaml v-rising homeylab/v-rising -n v-rising
```

#### OCI Registry Support
```bash
helm upgrade v-rising -n v-rising oci://registry-1.docker.io/homeylabcharts/v-rising --version X.Y.Z

# with own values file - recommended
helm upgrade -f my-values.yaml v-rising -n v-rising oci://registry-1.docker.io/homeylabcharts/v-rising --version X.Y.Z
```

## Configuration Options
For a full list of values, see [values.yaml](values.yaml). Some of the most important values are listed below.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config.logDays | int | `30` | optional lifetime of logfiles |
| config.serverName | string | `"v-rising"` | name of server |
| config.tz | string | `"America/New_York"` | timezone for server |
| config.worldName | string | `"v-rising-world"` | name of world |
| extraEnv | object | `{}` | additional environment variables as key value pairs |
| persistence.steamServer.enabled | bool | `true` | enable persistence using PVC for dedicated server files |
| persistence.steamServer.existingClaim | string | `""` | set an existingClaim for volume, if set the rest of persistence parameters are ignored |
| persistence.steamServer.mountPath | string | `"/mnt/vrising/server"` | set the mount path for the volume inside the container |
| persistence.steamServer.size | string | `"10Gi"` | set the size of the volume |
| persistence.steamServer.storageClass | string | `""` | set the storage class to use |
| persistence.world.enabled | bool | `true` | enable persistence using PVC for world files |
| persistence.world.existingClaim | string | `""` | set an existingClaim for volume, if set the rest of persistence parameters are ignored |
| persistence.world.mountPath | string | `"/mnt/vrising/persistentdata"` | set the mount path for the volume inside the container |
| persistence.world.size | string | `"5Gi"` | set the size of the volume |
| persistence.world.storageClass | string | `""` | set the storage class to use |
| resources.requests.cpu | string | `"500m"` |  |
| resources.requests.memory | string | `"8G"` |  |
| service.server.type | string | `"LoadBalancer"` | set type of service, example: `ClusterIP`, `NodePort`, `LoadBalancer` for v-rising server |
| service.server.gamePort.port | int | `9876` | set game port for v rising - if modified, manually edit the server config file |
| service.server.queryPort.port | int | `9877` | set query port for v rising - if modified, manually edit the server config file |
| service.rcon.enabled | bool | `true` | optional enable rcon service port - note: also needs modification of settings file. If enabled, manually edit the server config file |
| service.rcon.type | string | `"LoadBalancer"` | set type of service, example: `ClusterIP`, `NodePort`, `LoadBalancer` for rcon service |
| service.rcon.port | int | `25575` | rcon port for v rising |
