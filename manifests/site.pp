node default {
  package {'vim':}

$config_containerd = @(END)
disabled_plugins = []
END

  file { '/etc/containerd':
    ensure => 'directory',
  }

  file { '/etc/containerd/config.toml':
    ensure  => file,
    content => inline_template($config_containerd),
    require => File['/etc/containerd'],
  }

  class { 'docker':
    require => File['/etc/containerd/config.toml'],
  }

  class { 'selinux':
    mode => 'disabled'
  }

  $instances = lookup('terraform.instances')
  $tags = lookup("terraform.instances.${::hostname}.tags")

$host_template = @(END)
127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
<% @instances.each do |key, values| -%>
<%= values['local_ip'] %> <%= key %> <% if values['tags'].include?('puppet') %>puppet<% end %>
<% end -%>
END

  file { '/etc/hosts':
    ensure  => file,
    content => inline_template($host_template)
  }

  $api_server_count = size(lookup('terraform.tag_ip.controller'))

  $filteredControllers = $instances.filter |$name, $info| {
    'controller' in $info['tags']
  }
  $controllersIps = $filteredControllers.map |$name, $info| {
    "${name}:${info['local_ip']}"
  }

  $etcd_initial_cluster = $controllersIps.join(',')

  if 'controller' in $tags {
    class { 'kubernetes':
      api_server_count => $api_server_count,
      etcd_initial_cluster => $etcd_initial_cluster,
      controller => true,
      require    => [
        Class['selinux'],
        File['/etc/hosts']
      ]
    }
  } elsif 'worker' in $tags {
    class { 'kubernetes':
      api_server_count => $api_server_count,
      etcd_initial_cluster => $etcd_initial_cluster,
      worker  => true,
      require => [
        Class['selinux'],
        File['/etc/hosts']
      ]
    }
  }
}
