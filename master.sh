set -ex
# Prevent Docker from ruining iptables policy on FORWARD
mkdir /etc/systemd/system/docker.service.d
cat << EOF > /etc/systemd/system/docker.service.d/noiptables.conf
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --iptables=false
EOF
if [ "$proxy" ]; then
  cat << EOF > /etc/systemd/system/docker.service.d/proxy.conf
[Service]
Environment="HTTP_PROXY=$proxy"
EOF
fi
systemctl daemon-reload
# Install docker
apt-get install -y docker-ce=17.03.2~ce-0~ubuntu-xenial
# Configure kubelet to use pause image from Docker Hub
cat > /etc/systemd/system/kubelet.service.d/20-pod-infra-image.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--pod-infra-container-image=mirantisworkloads/pause-amd64:3.0"
EOF
systemctl daemon-reload
systemctl restart kubelet
# Run kubeadm
cat << EOF > /root/kubeadm.yaml
apiServerCertSANs:
- $floatingip
imageRepository: mirantisworkloads
token: $token
unifiedControlPlaneImage: mirantisworkloads/hyperkube-amd64:v1.8.7
EOF
modprobe br_netfilter
kubeadm init --config /root/kubeadm.yaml
# Copy kubeconfig to ubuntu user
mkdir -p ~ubuntu/.kube
cp /etc/kubernetes/admin.conf ~ubuntu/.kube/config
chown -R ubuntu:ubuntu ~ubuntu/.kube
# Install Calico and Tiller
export KUBECONFIG=/etc/kubernetes/admin.conf
until kubectl get nodes; do
  sleep 2
done
kubectl apply -f /root/calico.yaml
kubectl apply -f /root/tiller.yaml
