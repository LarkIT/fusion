class fusion(
  $install_dir = '/opt/fusion',
  $version     = '3.1.2',
  $url         = "https://s3-us-west-2.amazonaws.com/red-software/fusion-${version}.tar.gz",
  $lvsize      = '20G',
  $lvconfig    = {},
) {

  user { 'fusion' :
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
    ensure => directory
  }

  class { 'lvm':
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

  file_line { "Update fusion.properties":
    ensure => present,
    path   => "${install_dir}/${version}/conf/fusion.properties",
    line   => "group.default = zookeeper, solr, api, connectors, ui, spark-master, spark-worker",
    match  => "group.default = zookeeper, solr, api, connectors, ui",
  }
}
