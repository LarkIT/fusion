class fusion(
  $install_dir = '/opt/fusion',
  $version     = '3.1.2',
  $url         = "https://s3-us-west-2.amazonaws.com/red-software/fusion-${version}.tar.gz",
) {
#  include archive

  file{ '/opt/fusion':
    ensure => directory
  }

  #archive { "${install_dir}/fusion-${version}.tar.gz":
  archive { "/opt/fusion-${version}.tar.gz":
    source       => $url,
    extract      => true,
    extract_path => '/opt',
    creates      => '/opt/fusion/3.1.2'
    cleanup      => true,

  }

}
