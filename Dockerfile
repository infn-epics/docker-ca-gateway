## ===============================
#  1st stage: Download and Extract
FROM alpine AS download-extract
ARG REVISION=R2-1-3-0 

RUN apk update && apk add git
RUN git clone --branch ${REVISION} --depth 1 -c advice.detachedHead=false \
      https://github.com/epics-extensions/ca-gateway.git /ca-gateway
RUN rm -rf /ca-gateway/.git


## ===============================
#  2nd stage: build the CA Gateway
FROM baltig.infn.it:4567/epics-containers/epics-base AS builder

# Download the EPICS CA Gateway
COPY --from=download-extract /ca-gateway /epics/src/ca-gateway
RUN cd /epics/src/ca-gateway \
 && echo "EPICS_BASE=/epics/base" > configure/RELEASE.local \
 && echo "PCAS=/epics/base/modules/pcas" >> configure/RELEASE.local \
 && echo "INSTALL_LOCATION=/epics/ca-gateway" > configure/CONFIG_SITE.local \
 && make -j$(nproc) && make clean

## ===============================
FROM ubuntu:22.04 AS base
COPY --from=builder /epics/ /epics

CMD ["/epics/ca-gateway/gateway"]
#CMD ["-h"]
#CMD ["-help"]
