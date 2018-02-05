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
  CURL="curl -fSL --tr-encoding" && \
  cd usr/local/bin && \
  $CURL --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl} && \
  $CURL https://storage.googleapis.com/kubernetes-helm/helm-v2.8.0-linux-amd64.tar.gz | tar xzOf - linux-amd64/helm > helm && \
  chmod +x kubeadm kubelet kubectl helm && \
  cd /tmp && \
  $CURL "https://raw.githubusercontent.com/kubernetes/kubernetes/${RELEASE}/build/debs/kubelet.service" | sed "s:/usr/bin:/usr/local/bin:g" > etc/systemd/system/kubelet.service && \
  $CURL "https://raw.githubusercontent.com/kubernetes/kubernetes/${RELEASE}/build/debs/kubeadm-10.conf" | sed "s:/usr/bin:/usr/local/bin:g" > etc/systemd/system/kubelet.service.d/10-kubeadm.conf && \
  find | cpio -o -H newc | bzip2 > /package.cpio.bz2

RUN set -x && \
  cd /root && \
  /tmp/usr/local/bin/helm init --client-only && \
  /tmp/usr/local/bin/helm repo add mirantisworkloads https://mirantisworkloads.storage.googleapis.com/

COPY spinnaker-3.1.0.tgz /root/

RUN set -x && \
  cd /root && \
  tar cjf helm.tar.bz2 .helm spinnaker-*.tgz

FROM busybox
COPY --from=builder /package.cpio.bz2 /package.cpio.bz2
COPY --from=builder /root/helm.tar.bz2 /helm.tar.bz2
