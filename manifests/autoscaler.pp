class autoscaler ()
{
  $instances = lookup('terraform.instances')

  $pool_instances = $instances.filter |$name, $instance| {
    'pool' in $instance['tags']
  }
  $yaml_instances = $pool_instances.map |$name, $instance| {
    {
      $name => {
        'specs' => $instance['specs'],
      },
    }
  }

  $yaml_provider = {
    'tfe' => {
      'token' => lookup('tfe_token'),
      'workspace' => lookup('tfe_workspace')
    }
  }

  $yaml_content = {
    'provider' => $yaml_provider,
    'instances' => $yaml_instances,
  }

  file { '/etc/kubernetes/autoscaler.yaml':
    content => $yaml_content.to_yaml,
  }

  vcsrepo { '/etc/kubernetes/k8s-autoscaler':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/etiennedub/k8s-autoscaler-python.git',
  }

  exec { 'autoscaler_config':
    command     => 'kubectl create cm externalgrpc-autoscaler-cluster-config --from-file=autoscaler.yaml --namespace=kube-system -o yaml',
    path        => ['/usr/bin'],
    cwd         => '/etc/kubernetes/',
    environment => ['KUBECONFIG=/etc/kubernetes/admin.conf'],
    refreshonly => true,
    tries       => 4,
    try_sleep   => 15,
    timeout     => 15,
    require     => [
      File['/etc/kubernetes/autoscaler.yaml']
    ],
  }

  exec { 'autoscaler_deploy':
    command     => 'kubectl apply -f cluster-autoscaler-config.yaml -f ./cluster-autoscaler.yaml -f ./externalgrpc-autoscaler-service.yaml -f ./externalgrpc-autoscaler.yaml',
    path        => ['/usr/bin'],
    cwd         => '/etc/kubernetes/k8s-autoscaler/deploy',
    environment => ['KUBECONFIG=/etc/kubernetes/admin.conf'],
    refreshonly => true,
    tries       => 4,
    try_sleep   => 15,
    timeout     => 15,
    require     => [
      Exec['autoscaler_config'],
      Vcsrepo['/etc/kubernetes/k8s-autoscaler'],
      File['/etc/kubernetes/autoscaler.yaml']
    ],
  }
}
