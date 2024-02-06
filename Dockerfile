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
FROM pklaus/epics_base:7.0.4_debian AS builder

# The scs user already exists in base image.
# We set it here explicitly to clarify file ownership.
USER scs

# Download the EPICS CA Gateway
COPY --chown=scs:users --from=download-extract /ca-gateway /epics/src/ca-gateway
RUN cd /epics/src/ca-gateway \
 && echo "EPICS_BASE=/epics/base" > configure/RELEASE.local \
 && echo "PCAS=/epics/base/modules/pcas" >> configure/RELEASE.local \
 && echo "INSTALL_LOCATION=/epics/ca-gateway" > configure/CONFIG_SITE.local \
 && make -j$(nproc)


CMD ["/epics/ca-gateway/gateway"]
#CMD ["-h"]
#CMD ["-help"]
