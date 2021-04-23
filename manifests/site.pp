node /master\d+/ {
  package {'vim':}

  class { 'selinux': 
    mode => 'disabled'
  }

  class { 'kubernetes': 
    controller => true,
    require    => Class['selinux']
  }
}

node default {
  package {'vim':}

  class { 'selinux': 
    mode => 'disabled'
  }

  class { 'kubernetes': 
    worker => true,
    require    => Class['selinux']
  }
}
