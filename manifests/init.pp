class fusion(
  $install_dir = '/opt/fusion',
  $version     = '3.1.2',
  $url         = "https://s3-us-west-2.amazonaws.com/red-software/fusion-${version}.tar.gz",
  $manage_pkg  = true,
  $lvsize      = '20G',
  $lvconfig    = {},
) {

  user { 'fusion':
    ensure           => present,
    home             => $install_dir,
    password_max_age => '-1',
    managehome       => true,
  }

  $fusion_config_defaults = {
    'fusion_vg' =>
    {
      'physical_volumes' => ['/dev/xvdf'],
      'logical_volumes' => {
        'fusionlv' => { 'size' => $lvsize, 'mountpath' => $install_dir }
      }
    }
  }

  # Just in case we need to override the vg config
  $fusion_config_merged = deep_merge($fusion_config_defaults, $lvconfig)

  file{ $install_dir:
    ensure  => directory,
    require => User[ 'fusion' ],
  }

  class { 'lvm':
    manage_pkg    => $manage_pkg,
    volume_groups => $fusion_config_defaults,
    require       => File[ $install_dir ],
  }

  archive { "/opt/fusion-${version}.tar.gz":
    source       => $url,
    extract      => true,
    extract_path => '/opt',
    creates      => "${install_dir}/${version}",
    cleanup      => true,
    require      => Class[ 'lvm' ],
  }

  #file_line { "Update fusion.properties":
  #  ensure  => present,
  #  path    => "${install_dir}/${version}/conf/fusion.properties",
  #  line    => "group.default = zookeeper, solr, api, connectors, ui, spark-master, spark-worker",
  #  match   => "group.default = zookeeper, solr, api, connectors, ui",
  #  require => Archive[ "/opt/fusion-${version}.tar.gz" ],
  #}

  exec { "Fix Owner for ${install_dir}":
    command     => "/bin/chown -R fusion:fusion ${install_dir}",
    require     => Archive[ "/opt/fusion-${version}.tar.gz" ],
    subscribe   => Archive[ "/opt/fusion-${version}.tar.gz" ],
    logoutput   => true,
    refreshonly => true,
  }

  $hiera_ssh_keys = lookup('host_railsapp::global_ssh_keys', Hash, "first")

  $hiera_ssh_keys.each |$key,$value| {
    $ssh_key = $value['key']

    ssh_authorized_key { $key:
      ensure => present,
      user   => 'fusion',
      type   => 'ssh-rsa',
      key    => $ssh_key,
    }
  } 
  
  # Copy configuration files
  
  file { "/opt/fusion/${version}/conf":
    ensure  => directory,
    require => Archive[ "/opt/fusion-${version}.tar.gz" ],
    owner   => 'fusion',
    group   => 'fusion',
    mode    => '0644',
    notify  => Service['fusion'],
    source  => "puppet:///modules/${module_name}/${version}/conf",
    recurse => 'remote',
  }

  file { "/opt/fusion/${version}/apps":
    ensure  => file,
    require => Archive[ "/opt/fusion-${version}.tar.gz" ],
    owner   => 'fusion',
    group   => 'fusion',
    mode    => '0644',
    notify  => Service['fusion'],
    source  => "puppet:///modules/${module_name}/${version}/apps",
    recurse => 'remote',
  }

  # Install init script
  
  file { "/etc/systemd/system/fusion.service":
    ensure  => file,
    require => Archive[ "/opt/fusion-${version}.tar.gz" ],
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => "puppet:///modules/${module_name}/fusion.service",
  } ~>
  Exec['systemctl-daemon-reload']

  # Keep fusion running
  service { 'fusion':
    ensure => running,
    enable => true,
  }
}
