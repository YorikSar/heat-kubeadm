set -ex
apt-get install -y docker-ce=17.03.2~ce-0~ubuntu-xenial
kubeadm init --apiserver-cert-extra-sans $floatingip --token $token
mkdir -p ~ubuntu/.kube
cp /etc/kubernetes/admin.conf ~ubuntu/.kube/config
chown -R ubuntu:ubuntu ~ubuntu/.kube
export KUBECONFIG=/etc/kubernetes/admin.conf
until kubectl get nodes; do
  sleep 2
done
kubectl apply -f /root/calico.yaml
kubectl apply -f /root/tiller.yaml
