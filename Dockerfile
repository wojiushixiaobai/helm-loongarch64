ARG GO_VERSION=1.22

FROM cr.loongnix.cn/library/golang:${GO_VERSION}-buster as builder

ARG VERSION=v3.15.1

ARG WORK_DIR=/opt/helm

RUN set -ex; \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
    apt-get update; \
    apt-get install -y git file make zip unzip

ENV CGO_ENABLED=0

RUN --mount=type=cache,target=/go/pkg/mod \
    set -ex; \
    mkdir -p ${GOPATH}/pkg/mod/github.com/mitchellh; \
    go install github.com/xen0n/gox@go1.19 || true; \
    mv ${GOPATH}/pkg/mod/github.com/xen0n/gox@v* ${GOPATH}/pkg/mod/github.com/mitchellh/gox@v1.0.1; \
    cd ${GOPATH}/pkg/mod/github.com/mitchellh/gox@v1.0.1; \
    go install .

RUN set -ex; \
    git clone -b ${VERSION} --depth=1 https://github.com/helm/helm ${WORK_DIR}

WORKDIR ${WORK_DIR}

RUN --mount=type=cache,target=/go/pkg/mod \
    set -ex; \
    make build-cross TARGETS="linux/loong64" VERSION="${VERSION}"; \
    make dist checksum VERSION="${VERSION}"; \
    rm -rf _dist/linux-loong64

FROM cr.loongnix.cn/library/debian:buster-slim

WORKDIR /opt/helm

COPY --from=builder /opt/helm/_dist /opt/helm/dist

VOLUME /dist

CMD cp -rf dist/* /dist/