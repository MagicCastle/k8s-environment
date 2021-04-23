#!/bin/bash
cat << EOF > /etc/yum.repos.d/docker.repo
[docker]
name=Docker repo
baseurl=https://download.docker.com/linux/centos/7/x86_64/stable
gpgkey=https://download.docker.com/linux/centos/gpg
enabled=1
gpgcheck=1
EOF

yum -y install docker-ce
yum -y install PyYAML

systemctl start docker

k8s_version="1.20.0"
controllers=$(python bootstrap/controllers.py)
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
