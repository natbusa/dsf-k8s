#!/usr/bin/env bash

export K8S_BIN=$(pwd)/bin
export MINIKUBE_HOME=$(pwd)
export HELM_HOME=$(pwd)/.helm
export KUBE_HOME=$(pwd)/.kube
export KUBECONFIG=$(pwd)/.kube/config

$K8S_BIN/kubectl create clusterrolebinding permissive-binding \
 --clusterrole=cluster-admin \
 --user=admin \
 --user=kubelet \
 --group=system:serviceaccounts

# make sure the kubernetes cluster is running
$K8S_BIN/kubectl --namespace kube-system create sa tiller
$K8S_BIN/kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
$K8S_BIN/helm init --service-account tiller

#secure tiller-deploy
$K8S_BIN/kubectl --namespace=kube-system patch deployment tiller-deploy --type=json --patch='[{"op": "add", "path": "/spec/template/spec/containers/0/command", "value": ["/tiller", "--listen=localhost:44134"]}]'

####################################
# Helm: repos
$K8S_BIN/helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
$K8S_BIN/helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
$K8S_BIN/helm repo add monocular https://kubernetes-helm.github.io/monocular
$K8S_BIN/helm update

####################################
#Helm: default namespace

# helm: ingress
# helm install stable/nginx-ingress
  # Minikube/Kubeadm:
$K8S_BIN/helm install stable/nginx-ingress --name ingress --set controller.hostNetwork=true

#helm: monocular
$K8S_BIN/helm install monocular/monocular --name monocular

####################################
#Helm: (data science framework) dsf namespace

# helm: docker registry
$K8S_BIN/helm install stable/docker-registry --set persistence.size=1Gi,persistence.enabled=true --name registry --namespace dsf

# helm: concourse
$K8S_BIN/helm install stable/concourse --name concourse --namespace dsf

#check https://jupyterhub.github.io/helm-chart/ for the last version
$K8S_BIN/helm install jupyterhub/binderhub --name binder --namespace dsf --version=0.1.0-748c2f4 -f ./binderhub.minikube.yaml
