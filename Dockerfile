FROM golang:1.20-buster as builder

ARG HELM_VERSION=v3.12.1

ENV HELM_VERSION=${HELM_VERSION}

ARG WORK_DIR=/opt/helm

RUN set -ex; \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
    apt-get update; \
    apt-get install -y git file make zip unzip

ENV GOPROXY=https://goproxy.io \
    CGO_ENABLED=0

RUN set -ex; \
    mkdir -p ${GOPATH}/pkg/mod/github.com/mitchellh; \
    go install github.com/xen0n/gox@go1.19 || true; \
    mv ${GOPATH}/pkg/mod/github.com/xen0n/gox@v* ${GOPATH}/pkg/mod/github.com/mitchellh/gox@v1.0.1; \
    cd ${GOPATH}/pkg/mod/github.com/mitchellh/gox@v1.0.1; \
    go install .

RUN set -ex; \
    git clone -b ${HELM_VERSION} --depth=1 https://github.com/helm/helm ${WORK_DIR}

WORKDIR ${WORK_DIR}

RUN set -ex; \
    make build-cross TARGETS="linux/loong64" VERSION="${HELM_VERSION}"; \
    make dist checksum VERSION="${HELM_VERSION}"; \
    rm -rf _dist/linux-loong64

FROM debian:buster-slim

WORKDIR /opt/helm

COPY --from=builder /opt/helm/_dist /opt/helm/dist

VOLUME /dist

CMD cp -rf dist/* /dist/