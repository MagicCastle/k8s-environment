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

        $pool_instances = $instances.filter |$name, $instance| {
          'pool' in $instance['tags']
        }
        $yaml_content = $pool_instances.map |$name, $instance| {
          {
            $name => {
              'specs' => $instance['specs'],
            },
          }
        }.to_yaml

        notify{yaml_content:}
        file { '/tmp/test.yaml':
          content => $yaml_content,
        }

  if 'controller' in $tags {
    class { 'kubernetes':
      controller => true,
      require    => [
        Class['selinux'],
        File['/etc/hosts']
      ]
    }
  } elsif 'worker' in $tags {
    class { 'kubernetes':
      worker  => true,
      require => [
        Class['selinux'],
        File['/etc/hosts']
      ]
    }
  }
}
