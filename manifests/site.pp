node master1 {
  package {'vim':}

  class { 'selinux': 
    mode => 'disabled'
  }

  class { 'kubernetes': 
    controller => true,
    require    => Class['selinux']
  }
}

