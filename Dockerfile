FROM centos:latest

RUN yum -y install epel-release && \
    yum makecache fast && \
    yum install -y qemu-kvm iproute libvirt libvirt-client && \
    yum install -y python-pip openssh genisoimage net-tools && \
    pip install pyyaml && \
    yum clean all

ARG IMAGE
ARG TOOLS
RUN mkdir -p /cvp
ADD $IMAGE /cvp
ADD $TOOLS /cvp
RUN qemu-img create -f qcow2 -b /cvp/disk1.qcow2 /cvp/overlay_disk1.qcow2
RUN qemu-img create -f qcow2 -b /cvp/disk2.qcow2 /cvp/overlay_disk2.qcow2

EXPOSE 443
EXPOSE 9910

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

