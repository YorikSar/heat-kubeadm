FROM alpine as builder
RUN set -x && \
  apk update && \
  apk add curl

ENV CNI_VERSION="v0.5.1"
ENV RELEASE="v1.8.7"
RUN set -x && \
  set -o pipefail && \
  cd /tmp && \
  mkdir -p usr/local/bin opt/cni/bin etc/systemd/system/kubelet.service.d && \
  cd usr/local/bin && \
  curl -fL --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl} && \
  chmod +x kubeadm kubelet kubectl && \
  cd /tmp && \
  curl -fsSL "https://raw.githubusercontent.com/kubernetes/kubernetes/${RELEASE}/build/debs/kubelet.service" | sed "s:/usr/bin:/usr/local/bin:g" > etc/systemd/system/kubelet.service && \
  curl -fsSL "https://raw.githubusercontent.com/kubernetes/kubernetes/${RELEASE}/build/debs/kubeadm-10.conf" | sed "s:/usr/bin:/usr/local/bin:g" > etc/systemd/system/kubelet.service.d/10-kubeadm.conf && \
  find | cpio -o -H newc | bzip2 > /package.cpio.bz2

FROM busybox
COPY --from=builder /package.cpio.bz2 /package.cpio.bz2
