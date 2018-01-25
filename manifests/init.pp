class fusion(
  $install_dir = '/opt/fusion',
  $version     = '3.1.2',
  $url         = "https://s3-us-west-2.amazonaws.com/red-software/fusion-${version}.tar.gz",
  $lvsize      = '30G',
  $lvconfig    = {},
) {

  $fusion_config_defaults = {
    'fusion_vg' =>
    {
      'physical_volumes' => ['/dev/xvdf'],
      'logical_volumes' => {
        'fusionlv' => {
          'size'      => $lvsize,
          'mountpath' => $install_dir
        }
      }
     }
  }

  file{ '/opt/fusion':
    ensure => directory
  }

  class { 'lvm':
    volume_groups => $fusion_config_defaults,
  }

  archive { "/opt/fusion-${version}.tar.gz":
    source       => $url,
    extract      => true,
    extract_path => '/opt',
    creates      => "${install_dir}/${version}",
    cleanup      => true,
  }

}
