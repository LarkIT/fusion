class fusion(
  $install_dir = '/opt/fusion',
  $url         = 'https://s3-us-west-2.amazonaws.com/red-software/fusion-3.1.2.tar.gz'
) {

  file{ '/opt/fusion':
    ensure => directory
  }

  archive { $install_dir:
    source        => $url,
    extract       => true,
    extract_path  => $install_dir,
    extract_flags => '--strip 1 -zxvf',
    creates       => '/opt/fusion/3.1.2'
  }

}
