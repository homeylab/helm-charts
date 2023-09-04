FROM quay.io/helmpack/chart-testing:v3.9.0

RUN apk update && \
    apk add make

RUN mkdir -p /root/.kube

COPY --chmod=600 kube_config /root/.kube/config