################################################################################
#
#   This module manages sonar installation with docker. It generates 
#   a docker file containing the services details
#
# == Parameters
#
# [+install_dir+]
#   (OPTIONAL) (default: /opt/sonar)
#
#   the directory where the config files are stored
#
# [+base_data_dir+]
#   (OPTIONAL) (default: /srv/sonar)
#
#   the directory where all the data will be stored (sonar + database)
#
# [+log_dir+]
#
#   the directory where all the log files will be generated
#
# [+database_password+]
#   (MANDATORY)
#
#   The password used by sonar to connect to the database
#
# [+database_root_password+]
#   (MANDATORY)
#
#   The root database password
#
# [+mysql_innodb_buffer_pool_size+]
#   (MANDATORY)
#
#   The mysql buffer pool size to use
#
# [+sonar_container_labels+]
#   (OPTIONAL) (default: empty)
#
#  Additional labels de attach to the sonar container
#
# [+mysql_container_labels+]
#   (OPTIONAL) (default: empty)
#
#  Additional labels de attach to the mysql container
# [+front_network+]
#   (OPTIONAL) (default: undef)
#
#  Name of en eventual network to attach the sonar container on. 
#  Useful to allow a reverse proxy to reach the sonar container network
################################################################################
class sonar (
  $install_dir        = '/opt/sonar',
  $base_data_dir      = '/srv/sonar',
  $log_dir            = '/var/log/sonar',
  $database_password,
  $database_root_password,
  $mysql_innodb_buffer_pool_size        = '8g',
  $sonar_container_labels               = [],
  $mysql_container_labels               = [],
  $front_network                        = undef,
  $parameters                           = [],
  $install_crowd_plugin                 = false,
  $backup_db_user                       = 'backup',
  $backup_db_password                   = 'backup',
  $backup_history                       = 180,
  $backup_directory                     = '/var/backups/sonar',
  $backup_remote_user,
  $backup_remote_host,
  $backup_remote_directory,
) {

  include sonar::params

  ########################
  ## Directories
  ########################
  file { "${sonar::install_dir}/bin" :
    ensure      => directory,
    source      => 'puppet:///modules/sonar/bin',
    recurse     => true,
    owner       => 'root',
    group       => 'sonar',
    mode        => '750',
    require     => [File["${sonar::install_dir}"]]
  } ->
  file { "${sonar::log_dir}" :
    ensure      => directory,
  } ->
  file { "${sonar::base_data_dir}" :
    ensure      => directory,
  } ->
  file { "${sonar::params::data_dir}" :
    ensure      => directory,
  } ->
  file { "${sonar::params::extensions_dir}" :
    ensure      => directory,
  } ->
  file { "${sonar::params::extensions_dir}/plugins" :
    ensure      => directory,
  } ->
  file { "${sonar::params::mysql_data_dir}" :
    ensure      => directory,
    owner       => '999',
    group       => '999',
    mode        => '770',
  } ->
  file { "${sonar::params::mysql_config_dir}" :
    ensure      => directory,
    owner       => 'root',
    group       => '999',
    mode        => '644',
  } ->
  file { "${sonar::params::mysql_log_dir}" :
    ensure      => directory,
    owner       => 'root',
    group       => '999',
    mode        => '775',
  } ->
  file { "${sonar::install_dir}/mysql_init" :
    ensure      => directory,
  } ->
  file { "${sonar::backup_directory}" :
    ensure      => directory,
    owner       => 'sonar',
    group       => 'root',
    mode        => '770',
  }

  ########################
  ## Mysql configuration
  ########################
  file { "${sonar::params::mysql_config_dir}/sonar.cnf" :
    ensure      => present,
    content     => template ('sonar/sonar.cnf.erb'),
    owner       => 'root',
    group       => '999',
    mode        => '640',
  } -> file { "${sonar::install_dir}/mysql_init/user_backup.sql" :
    ensure      => present,
    content     => template ('sonar/mysql/user.sql.erb'),
    owner       => 'root',
    group       => '999',
    mode        => '640',
  }

  ########################
  ## Docker compose file
  ########################
  file { "${sonar::install_dir}/docker-compose.yml" :
    ensure      => 'present',
    content     => template ('sonar/docker-compose.yml.erb'),
    owner       => 'root',
    group       => 'root',
    mode        => '640',
  }

  ########################
  ## Crowd plugin
  ########################
  if $sonar::install_crowd_plugin == true {
    wget::fetch { 'sonar_crowd':
      source_url          => "http://downloads.sonarsource.com/plugins/org/codehaus/sonar-plugins/sonar-crowd-plugin/2.0/sonar-crowd-plugin-2.0.jar",
      target_directory    => "${sonar::params::extensions_dir}/plugins",
      target_file         => "sonar-crowd-plugin-2.0.jar",
      require             => File["${sonar::params::extensions_dir}/plugins"],
      notify              => Docker_compose["${sonar::install_dir}/docker-compose.yml"],
    }
  }

  ###########################
  #  Launch the containers
  ###########################
  docker_compose { "${sonar::install_dir}/docker-compose.yml" :
    ensure  => 'present',
    require => [
      Class['docker::compose'],
      File["${sonar::install_dir}/docker-compose.yml"],
    ],
  }

  ###########################
  #  scripts configuration
  ###########################
  file { "${sonar::install_dir}/bin/_setenv.sh" :
    ensure  => 'present',
    content => template('sonar/bin/_setenv.sh.erb'),
    owner       => 'root',
    group       => 'sonar',
    mode        => '750',
    require     => [File["${sonar::install_dir}/bin"]]
  }

}