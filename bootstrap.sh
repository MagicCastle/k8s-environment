#!/bin/bash
yum -y install python36

puppet apply /etc/puppetlabs/code/environments/main/manifests/site.pp  --tags mc_bootstrap
puppet apply /etc/puppetlabs/code/environments/main/manifests/site.pp  --tags kubernetes::repos
puppet apply /etc/puppetlabs/code/environments/main/manifests/site.pp  --tags kubernetes::packages

k8s_version="1.28.0"
controllers=$(python3 bootstrap/controllers.py)
kubetool_version=$(grep 'puppetlabs-kubernetes' Puppetfile| cut -d, -f2 | sed -e 's/^ //g' -e "s/'//g")

docker run --rm -v $(pwd)/data:/mnt \
    -e OS=centos\
    -e VERSION=${k8s_version}\
    -e CONTAINER_RUNTIME=docker\
    -e CNI_PROVIDER=flannel\
    -e ETCD_INITIAL_CLUSTER=${controllers}\
    -e ETCD_IP="%{networking.ip}"\
    -e KUBE_API_ADVERTISE_ADDRESS="%{networking.ip}"\
    -e INSTALL_DASHBOARD=true\
    puppet/kubetool:${kubetool_version}

mv data/Centos.yaml data/k8s.yaml
