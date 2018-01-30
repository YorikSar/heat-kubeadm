set -ex
apt-get install -y docker-ce=17.03.2~ce-0~ubuntu-xenial
kubeadm init --apiserver-cert-extra-sans $floatingip --token $token
mkdir -p ~ubuntu/.kube
cp /etc/kubernetes/admin.conf ~ubuntu/.kube/config
chown -R ubuntu:ubuntu ~ubuntu/.kube
until curl -sLo /dev/null http://localhost:8080/swagger-2.0.0.pb-v1; do
  sleep 2
done
kubectl apply -f https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml
