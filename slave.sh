set -ex
apt-get install -y docker-ce=17.03.2~ce-0~ubuntu-xenial
kubeadm join --token $token --discovery-token-unsafe-skip-ca-verification $master_ip:6443
