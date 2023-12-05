# nut-exporter
This chart provides (nut_exporter)[https://github.com/DRuggeri/nut_exporter] (docker) image[https://hub.docker.com/r/druggeri/nut_exporter] from `DRuggeri` repository. 

## Add Chart Repo
```
helm repo add homeylab https://homeylab.github.io/helm-charts/
helm repo update homeylab
```

## Install
```
helm install nut-exporter  homeylab/nut-exporter -n nut-exporter  --create-namespace

# with own values file - recommended
helm install -f my-values.yaml homeylab/nut-exporter  -n nut-exporter  --create-namespace
```

## Upgrade
```
helm upgrade nut-exporter homeylab/nut-exporter -n nut-exporter

# with own values file - recommended
helm upgrade -f my-values.yaml nut-exporter homeylab/nut-exporter -n nut-exporter
```

## Configuration Options


### Scraping Multiple NUT Servers
For setting up metrics for multiple UPS servers from a single instance, follow upstream [documentation](https://github.com/DRuggeri/nut_exporter#example-prometheus-scrape-configurations) on using multiple `scrape_configs` targets in Prometheus.
