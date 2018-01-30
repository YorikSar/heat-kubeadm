set -ex
# Prevent Docker from ruining iptables policy on FORWARD
mkdir /etc/systemd/system/docker.service.d
cat << EOF > /etc/systemd/system/docker.service.d/noiptables.conf
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --iptables=false
EOF
systemctl daemon-reload
# Install docker
apt-get install -y docker-ce=17.03.2~ce-0~ubuntu-xenial
# Run kubeadm
modprobe br_netfilter
kubeadm init --apiserver-cert-extra-sans $floatingip --token $token
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
