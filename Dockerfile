
FROM baltig.infn.it:4567/epics-containers/epics-base AS builder
ARG REVISION=R2-1-3-0 


RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends build-essential git ca-certificates
# Download the EPICS CA Gateway
RUN git clone --branch ${REVISION} --depth 1 -c advice.detachedHead=false \
      https://github.com/epics-extensions/ca-gateway.git /ca-gateway
RUN git clone https://github.com/epics-modules/pcas.git /pcas
RUN cd /pcas \
 && echo "EPICS_BASE=/epics/epics-base" > configure/RELEASE.local \
 && echo "INSTALL_LOCATION=/epics/pcas" > configure/CONFIG_SITE.local \
 && make -j$(nproc) && make clean

RUN rm -rf /ca-gateway/.git /pcas/.git

RUN cd /ca-gateway \
 && echo "EPICS_BASE=/epics/epics-base" > configure/RELEASE.local \
 && echo "PCAS=/epics/pcas" >> configure/RELEASE.local \
 && echo "INSTALL_LOCATION=/epics/ca-gateway" > configure/CONFIG_SITE.local \
 && make -j$(nproc) && make clean

## ===============================
FROM ubuntu:22.04 AS base
COPY --from=builder /epics/ /epics

CMD ["/epics/ca-gateway/gateway"]
#CMD ["-h"]
#CMD ["-help"]
