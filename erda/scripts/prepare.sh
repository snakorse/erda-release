#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")"

export ssl_dir="$(pwd)/ssl"
export helm_package="../package"

. fn-ssl

rm -rf 

# export NAMESPACE and SIZE variables
if [[ -z $ERDA_NAMESPACE ]]; then
	export ERDA_NAMESPACE="default"
fi

if [[ -z $ERDA_SIZE ]]; then
	export ERDA_SIZE="demo"
fi 

# enable the netportal, `enable` and `disable` supported, default is `enable`
if [[ -z $ERDA_NETPORTAL_ENABLE ]]; then
	export ERDA_NETPORTAL_ENABLE=enable
fi

# set necessary label of erda to the Kubernetes, `enable` and `disable` supported, default is `enable`
if [[ -z $ERDA_LABEL_ENABLE ]]; then
	export ERDA_LABEL_ENABLE=enable
fi

# set the network of registry host mode, `host` and `container` supported, default is `container`
if [[ -z $ERDA_REGISTRY_NETMODE ]]; then
	export ERDA_REGISTRY_NETMODE=host
fi

# set domain for erda
if [[ -z $ERDA_GENERIC_DOMAIN ]]; then
	export ERDA_GENERIC_DOMAIN="erda.io"
fi

# set Erda cluster name
if [[ -z $ERDA_CLUSTER_NAME ]]; then
	export ERDA_CLUSTER_NAME="erda-demo"
fi

if [[ -z $ERDA_LB_NODES ]]; then
	export ERDA_LB_NODES=`kubectl get node -o wide | awk '{print $1}' | grep -v NAME | head -n 1`
fi

etcd_sans=(
  erda-etcd.${ERDA_NAMESPACE}.svc.cluster.local
  127.0.0.1
  localhost
)


kubeconf="$HOME/.kube/config"

# set Kubernetes APISERVER VIP

export KUBERNETES_APISERVERVIP=`kubectl get svc | grep kubernetes | awk '{print $3}'`:443

# set Kubernetes Master

export KUBERNETES_MASTERIP=$(grep -F server "$kubeconf" | awk '{print $2}')

# set Kubernetes NodeLabel

if [[ $ERDA_LABEL_ENABLE != "disable" ]]; then

	for i in `kubectl get nodes | grep -v NAME | awk '{print $1}'`;
	do
		kubectl label node $i dice/pack-job=true dice/stateful-service=true dice/stateless-service=true dice/workspace-dev=true dice/workspace-prod=true dice/workspace-staging=true dice/workspace-test=true --overwrite
	done

	for i in ${ERDA_LB_NODES};
	do
		kubectl label node $i dice/lb=true --overwrite
	done

fi

rm -rf $ssl_dir
mkdir $ssl_dir

# generate the etcd certificate authority, peer server crt and client crt files
gen_ca etcd-ca etcd-ca
gen_server etcd-ca etcd-peer etcd-peer c "${etcd_sans[@]}"
gen_server etcd-ca etcd-server etcd-server c "${etcd_sans[@]}"
gen_client etcd-ca etcd-client etcd-client

export ETCD_CA=`cat ${ssl_dir}/etcd-ca.pem | base64 | tr -d "\n"`
export ETCD_PEER=`cat ${ssl_dir}/etcd-peer.pem | base64 | tr -d "\n"`
export ETCD_PEER_KEY=`cat ${ssl_dir}/etcd-peer-key.pem | base64 | tr -d "\n"`
export ETCD_SERVER=`cat ${ssl_dir}/etcd-server.pem | base64 | tr -d "\n"`
export ETCD_SERVER_KEY=`cat ${ssl_dir}/etcd-server-key.pem | base64 | tr -d "\n"`
export ETCD_CLIENT=`cat ${ssl_dir}/etcd-client.pem | base64 | tr -d "\n"`
export ETCD_CLIENT_KEY=`cat ${ssl_dir}/etcd-client-key.pem | base64 | tr -d "\n"`

# Set Registry HostIP
export ERDA_REGISTRY_HOSTURL=""
export ERDA_REGISTRY_HOSTNAME=""

if [[ $ERDA_REGISTRY_NETMODE == "host" ]]; then
	export ERDA_REGISTRY_HOSTNAME=`kubectl get nodes | grep -v NAME |head -n 1 |awk '{print $1}'`
	export ERDA_REGISTRY_HOSTURL=`kubectl get nodes -o wide | grep -v NAME |head -n 1 |awk '{print $6}'`:5000
else
	export ERDA_REGISTRY_NETMODE="container"
fi


# compose secrets and helm values files from telmpate files
envsubst < ../templates/etcd-server-secret.yaml > ../erda-addons/templates/etcd/etcd-server-secret.yaml
envsubst < ../templates/etcd-client-secret.yaml > ../erda-addons/templates/etcd/etcd-client-secret.yaml
envsubst < ../templates/addons_values.yaml > ../erda-addons/values.yaml
envsubst < ../templates/base_values.yaml > ../erda-base/values.yaml
envsubst < ../templates/erda_values.yaml > ../erda/values.yaml

# compose the netportal certificate authority files，client and server files temporary
if [[ $ERDA_NETPORTAL_ENABLE != "" ]]; then

	gen_ca netportal-ca netportal-ca
	gen_client netportal-ca netportal-central netportal.terminus.io
	gen_server netportal-ca netportal-edge netportal.terminus.io "" netportal.terminus.io

	export KUBERNETES_CA=$(grep -F certificate-authority-data "$kubeconf" | awk '{print $2}')
	export ADMIN_PEM=$(grep -F client-certificate-data "$kubeconf" | awk '{print $2}')
	export ADMIN_KEY_PEM=$(grep -F client-key-data "$kubeconf" | awk '{print $2}')
	export NETPORTAL_CA=`cat ${ssl_dir}/netportal-ca.pem | base64 | tr -d "\n"`
	export NETPORTAL_EDGE=`cat ${ssl_dir}/netportal-edge.pem | base64 | tr -d "\n"`
	export NETPORTAL_EDGE_KEY=`cat ${ssl_dir}/netportal-edge-key.pem | base64 | tr -d "\n"`
	export NETPORTAL_CENTRAL=`cat ${ssl_dir}/netportal-central.pem | base64 | tr -d "\n"`
	export NETPORTAL_CENTRAL_KEY=`cat ${ssl_dir}/netportal-central-key.pem | base64 | tr -d "\n"`

	envsubst < ../templates/netportal.yaml > ../erda-addons/templates/ingress/netportal.yaml
	envsubst < ../templates/netportal-admin.yaml > ../erda-addons/templates/ingress/netportal-admin.yaml
	envsubst < ../templates/netportal-edge.yaml > ../erda-addons/templates/ingress/netportal-edge.yaml

	
	kubectl delete -f ../nginx_tlmp.yaml --ignore-not-found=true
	kubectl create -f ../nginx_tlmp.yaml

fi


# package the helm package
rm -rf ${helm_package}
mkdir ${helm_package}

helm package ../erda-base -d ${helm_package}
helm package ../erda-addons -d ${helm_package}
helm package ../erda -d ${helm_package}

kubectl delete job erda-init-image --ignore-not-found=true
