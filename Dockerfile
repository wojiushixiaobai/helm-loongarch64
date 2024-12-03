ARG GO_VERSION=1.22

FROM cr.loongnix.cn/library/golang:${GO_VERSION}-buster AS builder

ARG GORELEASER_VERSION=latest

RUN --mount=type=cache,target=/go/pkg/mod \
    set -ex; \
    go install github.com/goreleaser/goreleaser@${GORELEASER_VERSION}

ARG VERSION

ARG WORK_DIR=/opt/helm

RUN set -ex \
    && git clone -b ${VERSION} --depth=1 https://github.com/helm/helm ${WORK_DIR}

ADD .goreleaser.yml /opt/.goreleaser.yml
WORKDIR ${WORK_DIR}

RUN --mount=type=cache,target=/go/pkg/mod \
    set -ex \
    && K8S_MODULES_VER=$(go list -f '{{.Version}}' -m k8s.io/client-go | sed 's/^v//' | tr '.' ' ') \
    && export VERSION_METADATA="" \
    && export GIT_DIRTY="clean" \
    && export K8S_MODULES_MAJOR_VER=$(( $(echo $K8S_MODULES_VER | awk '{print $1}') + 1 )) \
    && export K8S_MODULES_MINOR_VER=$(echo $K8S_MODULES_VER | awk '{print $2}') \
    && goreleaser --config /opt/.goreleaser.yml release --skip=publish --clean

FROM cr.loongnix.cn/library/debian:buster-slim

ARG WORK_DIR=/opt/helm

WORKDIR ${WORK_DIR}

COPY --from=builder /opt/helm/dist /opt/helm/dist

VOLUME /dist

CMD cp -rf dist/* /dist/