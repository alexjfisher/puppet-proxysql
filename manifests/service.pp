# == Class proxysql::service
#
# This class is meant to be called from proxysql.
# It ensure the service is running.
#
class proxysql::service {

  if versioncmp($proxysql::version, '2.0.7') >= 0 and fact('os.family') == 'RedHat' and versioncmp(fact('os.release.major'),'7') >= 0 {
    # From this version, official packages started using systemd
    unless extlib::has_module('camptocamp/systemd') { fail('camptocamp/systemd module is missing from modulepath') }
    $drop_in_ensure = $proxysql::restart ? {
      true  => 'present',
      false => 'absent',
    }
    systemd::dropin_file { 'proxysql ExecStart override':
      ensure   => $drop_in_ensure,
      filename => 'puppet.conf',
      unit     => "${proxysql::service_name}.service",
      content  => "[Service]\nExecStart=\nExecStart=/usr/bin/proxysql --reload -c /etc/proxysql.cnf\n",
      notify   => Service[$proxysql::service_name],
    }
    service { $proxysql::service_name:
      ensure => $proxysql::service_ensure,
      enable => true,
    }
  } else {
    if $proxysql::restart {
      service { $proxysql::service_name:
        ensure     => $proxysql::service_ensure,
        enable     => true,
        hasstatus  => true,
        hasrestart => false,
        provider   => 'base',
        status     => '/etc/init.d/proxysql status',
        start      => '/usr/bin/proxysql --reload',
        stop       => '/etc/init.d/proxysql stop',
      }
    } else {
      service { $proxysql::service_name:
        ensure     => $proxysql::service_ensure,
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
      }
    }
  }

  exec { 'wait_for_admin_socket_to_open':
    command   => "test -S ${proxysql::admin_listen_socket}",
    unless    => "test -S ${proxysql::admin_listen_socket}",
    tries     => '3',
    try_sleep => '10',
    require   => Service[$proxysql::service_name],
    path      => '/bin:/usr/bin',
  }

}
