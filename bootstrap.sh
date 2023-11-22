#!/bin/bash
cat << EOF > /etc/yum.repos.d/docker.repo
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://download.docker.com/linux/centos/\$releasever/\$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF

yum -y install docker-ce
yum -y install python36

sed -i -e 's/disabled_plugins/#disabled_plugins/' /etc/containerd/config.toml
systemctl restart containerd

systemctl start docker && systemctl enable docker

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
