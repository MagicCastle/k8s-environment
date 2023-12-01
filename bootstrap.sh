#!/bin/bash
yum -y install python36

curl -L https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssl_1.6.4_linux_amd64 -o /usr/local/bin/cfssl
curl -L https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssljson_1.6.4_linux_amd64 -o /usr/local/bin/cfssljson
chmod +x /usr/local/bin/cfssl /usr/local/bin/cfssljson
/opt/puppetlabs/puppet/bin/gem install slop

controllers=$(python3 bootstrap/controllers.py)
export OS=centos
export ETCD_INITIAL_CLUSTER=${controllers}
/opt/puppetlabs/puppet/bin/ruby /etc/puppetlabs/code/environments/production/modules/kubernetes/tooling/kube_tool.rb

python3 bootstrap/merge_yaml.py
cp *.yaml ./data
