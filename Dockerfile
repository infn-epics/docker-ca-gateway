
FROM baltig.infn.it:4567/epics-containers/epics-base AS builder

RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends build-essential git
# Download the EPICS CA Gateway
RUN git clone --branch ${REVISION} --depth 1 -c advice.detachedHead=false \
      https://github.com/epics-extensions/ca-gateway.git /ca-gateway
RUN rm -rf /ca-gateway/.git

RUN cd /ca-gateway \
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
