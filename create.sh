#!/usr/bin/env bash

expot K8S_DSF_ROOT=

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
$K8S_BIN/helm repo update

####################################
#Helm: default namespace

####################################
#Helm: (data science framework) dsf namespace

# helm: docker registry
$K8S_BIN/helm install stable/docker-registry --set persistence.size=10Gi,persistence.enabled=true --name registry --namespace dsf

# helm: concourse
$K8S_BIN/helm install stable/concourse --set persistence.worker.size=5Gi --name concourse --namespace dsf

#check https://jupyterhub.github.io/helm-chart/ for the last version
$K8S_BIN/helm install jupyterhub/binderhub --name binder --namespace dsf --version=0.1.0-748c2f4 -f ./binderhub.minikube.yaml
$K8S_BIN/helm upgrade binder jupyterhub/binderhub --name binder --version=0.1.0-748c2f4 -f ./binderhub.minikube.yaml

######
$K8S_BIN/helm list
$K8S_BIN/kubectl get nodes,pods,svc,pv,pvc -n dsf
$K8S_BIN/minikube dashboard&

######
#expose the services to the hostpath

CONCOURSE_POD_NAME=$($K8S_BIN/kubectl get pods --namespace dsf -l "app=concourse-web" -o jsonpath="{.items[0].metadata.name}")
$K8S_BIN/kubectl port-forward --namespace dsf $CONCOURSE_POD_NAME 8080:8080 &
