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
################################################################################
class sonar (
  $install_dir        = '/opt/sonar',
  $base_data_dir      = '/srv/sonar',
  $log_dir            = '/var/log/sonar',
  $database_password,
  $database_root_password,
  $mysql_innodb_buffer_pool_size       = '8g',
) {

  include sonar::params

  ########################
  ## Directories
  ########################
  file { "${sonar::install_dir}" :
    ensure      => directory,
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

  ########################
  ## Mysql configuration
  ########################
  file { "${sonar::params::mysql_config_dir}/sonar.cnf" :
    ensure      => present,
    content     => template ('sonar/sonar.cnf.erb'),
    owner       => 'root',
    group       => '999',
    mode        => '640',
  } ->

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

}