# docker build . -t cosmwasm/wasmd:latest
# docker run --rm -it cosmwasm/wasmd:latest /bin/sh
FROM golang:1.19-alpine3.15 AS go-builder
ARG arch=aarch64

# this comes from standard alpine nightly file
#  https://github.com/rust-lang/docker-rust-nightly/blob/master/alpine3.12/Dockerfile
# with some changes to support our toolchain, etc
RUN set -eux; apk add --no-cache ca-certificates build-base;

RUN apk add git
# NOTE: add these to run with LEDGER_ENABLED=true
# RUN apk add libusb-dev linux-headers

WORKDIR /code
COPY . /code/
# See https://github.com/CosmWasm/wasmvm/releases
ADD https://github.com/CosmWasm/wasmvm/releases/download/v1.2.4/libwasmvm_muslc.aarch64.a /lib/libwasmvm_muslc.aarch64.a
ADD https://github.com/CosmWasm/wasmvm/releases/download/v1.2.4/libwasmvm_muslc.x86_64.a /lib/libwasmvm_muslc.x86_64.a
RUN sha256sum /lib/libwasmvm_muslc.aarch64.a | grep 682a54082e131eaff9beec80ba3e5908113916fcb8ddf7c668cb2d97cb94c13c
RUN sha256sum /lib/libwasmvm_muslc.x86_64.a | grep ce3d892377d2523cf563e01120cb1436f9343f80be952c93f66aa94f5737b661

# Copy the library you want to the final location that will be found by the linker flag `-lwasmvm_muslc`
RUN cp /lib/libwasmvm_muslc.${arch}.a /lib/libwasmvm_muslc.a
RUN echo $(ls -la /lib/libwasmvm_muslc.a)

# force it to use static lib (from above) not standard libgo_cosmwasm.so file
RUN LEDGER_ENABLED=false BUILD_TAGS=muslc LINK_STATICALLY=true make build
RUN echo "Ensuring binary is statically linked ..." \
  && (file /code/build/pollyad | grep "statically linked")

# --------------------------------------------------------
FROM alpine:3.15

COPY --from=go-builder /code/build/pollyad /usr/bin/pollyad

COPY docker/* /opt/
RUN chmod +x /opt/*.sh

COPY ./explorer /opt/



RUN apk update && \
    apk add nodejs npm supervisor

RUN mkdir -p /run/openrc && touch /run/openrc/softlevel

WORKDIR /opt

RUN npm install -g next
RUN npm cache clean --force
RUN npm install
RUN npm run build

RUN cp /opt/explorer.service /etc/supervisord.conf

# rest server
EXPOSE 1317
# tendermint p2p
EXPOSE 26656
# tendermint rpc
EXPOSE 26657
# Explorer
EXPOSE 3000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]