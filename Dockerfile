FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# renovate: datasource=pypi depName=ansible
ARG ANSIBLE_VERSION=7.6.0
ARG TARGETPLATFORM

RUN \
 apt-get update && \
 apt-get install -y \
      apache2 \
      binutils-dev \
      binutils-aarch64-linux-gnu \
      binutils-x86-64-linux-gnu \
      build-essential \
      dosfstools \
      figlet \
      gcc-aarch64-linux-gnu \
      gcc-x86-64-linux-gnu \
      genisoimage \
      git \
      isolinux \
      liblzma-dev \
      libslirp-dev \
      python3-pip \
      python3-setuptools \
      toilet

# syslinux is linux/amd64 only, but it is required to build hybrid ISOs
# the netboot.xyz build process will print a warning when building on other
# architectures that these hybrid images will not be generated
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then apt-get install -y syslinux syslinux-common; fi

RUN pip3 install ansible==${ANSIBLE_VERSION}

# Let's warn users when they're using a builder image that does not include syslinux
# Pass on the architecture built for and a pre-formatted warning message to child images
ENV NETBOOTXYZ_BUILDER_ARCH ${TARGETPLATFORM}
ENV NETBOOTXYZ_BUILDER_ISOHYBRID_MESSAGE "\033[0;31mWARNING\033[0m: \
    The builder image being used is missing isohybrid due to being built for the ${TARGETPLATFORM} architecture.\n \
    As a result no multi-arch images will be generated when building using this image."

# Trigger the message to show in child images
ONBUILD ARG BUILDPLATFORM
# Redefining this as ARG prevents the message from showing up in build output and potentially confuse users
ONBUILD ARG NETBOOTXYZ_ISOHYBRID_MESSAGE ${NETBOOTXYZ_BUILDER_ISOHYBRID_MESSAGE}
ONBUILD RUN \
  if [ "$NETBOOTXYZ_BUILDER_ARCH" != "linux/amd64" ]; then \
  printf ${NETBOOTXYZ_ISOHYBRID_MESSAGE}; \
  fi
