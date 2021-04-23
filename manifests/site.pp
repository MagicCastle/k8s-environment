node default {
  package {'vim':}

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
