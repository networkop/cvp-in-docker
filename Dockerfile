FROM centos:latest

RUN yum -y install epel-release && \
    yum makecache fast && \
    yum install -y qemu-kvm iproute libvirt libvirt-client && \
    yum install -y python-pip openssh genisoimage net-tools && \
    pip install pyyaml && \
    yum clean all

ARG IMAGE
ARG TOOLS=cvp-tools-2018.2.2.tgz
RUN mkdir -p /cvp
ADD $IMAGE /cvp
ADD $TOOLS /cvp

EXPOSE 443
EXPOSE 9910

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

