#!/usr/bin/env bash

export K8S_BIN=$(pwd)/bin
export MINIKUBE_HOME=$(pwd)
export HELM_HOME=$(pwd)/.helm
export KUBE_HOME=$(pwd)/.kube
export KUBECONFIG=$(pwd)/.kube/config

mkdir -p $K8S_BIN
mkdir -p $KUBE_HOME
mkdir -p $HELM_HOME

#minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube
mv minikube $K8S_BIN

#kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
mv kubectl $K8S_BIN

# Helm
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | sed 's/sudo //g' | HELM_INSTALL_DIR=$(pwd)/bin bash

# executables
chmod +x $K8S_BIN/*kube*

# start Minikube
$K8S_BIN/minikube start --vm-driver=virtualbox --bootstrapper kubeadm --disk-size 64G --memory 12288 --cpus 4

# from https://gist.github.com/minrk/22abe39fbc270c3f3f1d4771a287c0b5

$K8S_BIN/minikube ssh "
  sudo ip link set docker0 promisc on
  # make hostpath volumes world-writable by default
  sudo chmod -R a+rwX /tmp/hostpath-provisioner/
  sudo setfacl -d -m u::rwX /tmp/hostpath-provisioner/
"
