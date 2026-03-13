ARG IMAGE_EXT
ARG BASE=7.0.9ec4
ARG REGISTRY=ghcr.io/epics-containers
ARG RUNTIME=${REGISTRY}/epics-base${IMAGE_EXT}-runtime:${BASE}
ARG DEVELOPER=${REGISTRY}/epics-base${IMAGE_EXT}-developer:${BASE}
ARG REVISION=R2-1-3-0 
FROM  ${DEVELOPER} AS developer
ARG REVISION


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
FROM ${RUNTIME} AS base
COPY --from=developer /epics/ /epics
RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    libreadline8t64 git ca-certificates iputils-ping iproute2 telnet \
    && rm -rf /var/lib/apt/lists/* 
ARG USER_ID=epics
ARG USER_UID=1000
ARG GROUP_ID=control
ARG GROUP_UID=1000


RUN groupadd -r ${GROUP_ID} -g ${GROUP_UID} && useradd -r -g ${GROUP_ID} -u ${USER_UID} ${USER_ID}

RUN chown -R ${USER_UID}:${GROUP_UID} /epics
USER ${USER_ID}

ENV PATH=/epics/ca-gateway/bin/linux-x86_64/:/epics/epics-base/bin/linux-x86_64/:$PATH
CMD ["/epics/ca-gateway/bin/linux-x86_64/gateway"]
#CMD ["-h"]
#CMD ["-help"]
