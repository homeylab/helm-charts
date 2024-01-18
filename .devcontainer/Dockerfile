FROM quay.io/helmpack/chart-testing:v3.10.1

RUN apk update && \
    apk add make

RUN adduser -D -s /bin/ash -u 1000 vscode

USER vscode

RUN mkdir -p /home/vscode/.kube

COPY --chmod=600 --chown=vscode:vscode kube_config /home/vscode/.kube/config