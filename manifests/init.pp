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
  $version                              = '6.7.5-alpine',
  $version_crowdin_plugin               = '2.0',
  $version_exo_rules                    = '1.0.0',
  $install_dir                          = '/opt/sonar',
  $base_data_dir                        = '/srv/sonar',
  $log_dir                              = '/var/log/sonar',
  $database_password,
  $database_root_password,
  $mysql_innodb_buffer_pool_size        = '8g',
  $mysql_expose_port_locally            = false,
  $sonar_container_labels               = [],
  $mysql_container_labels               = [],
  $front_network                        = undef,
  $parameters                           = [],
  $install_crowd_plugin                 = false,
  $install_exo_rules                    = false,
  $backup_db_user                       = 'backup',
  $backup_db_password                   = 'backup',
  $backup_history                       = 180,
  $backup_directory                     = '/var/backups/sonar',
  $backup_remote_user,
  $backup_remote_host,
  $backup_remote_directory,
  $es_heap                              = '2g',
) {

  include sonar::params

  ########################
  ## Directories
  ########################
  file { "${sonar::install_dir}/bin" :
    ensure  => directory,
    source  => 'puppet:///modules/sonar/bin',
    recurse => true,
    owner   => 'root',
    group   => 'sonar',
    mode    => '0750',
    require => File[$sonar::install_dir]
  }
  -> file { $sonar::log_dir :
    ensure      => directory,
  }
  -> file { $sonar::base_data_dir :
    ensure      => directory,
  }
  -> file { $sonar::params::data_dir :
    ensure      => directory,
  }
  -> file { $sonar::params::extensions_dir :
    ensure      => directory,
  }
  -> file { "${sonar::params::extensions_dir}/plugins" :
    ensure      => directory,
  }
  -> file { $sonar::params::sonar_conf_dir :
    ensure => directory,
    owner  => '999',
    group  => '999',
    mode   => '0770',
  }
  -> file { $sonar::params::mysql_data_dir :
    ensure => directory,
    owner  => '999',
    group  => '999',
    mode   => '0770',
  }
  -> file { $sonar::params::mysql_conf_dir :
    ensure => directory,
    owner  => 'root',
    group  => '999',
    mode   => '0644',
  }
  -> file { $sonar::params::mysql_log_dir :
    ensure => directory,
    owner  => 'root',
    group  => '999',
    mode   => '0775',
  }
  -> file { "${sonar::install_dir}/mysql_init" :
    ensure      => directory,
  }
  -> file { $sonar::backup_directory :
    ensure => directory,
    owner  => 'sonar',
    group  => 'root',
    mode   => '0770',
  }

  ########################
  ## Mysql configuration
  ########################
  file { '/sonar.cnf': # 2019-01-31 : this could be removed when applied everywhere
    ensure => absent
  }
  file { "${sonar::params::mysql_conf_dir}/sonar.cnf" :
    ensure  => present,
    content => template ('sonar/sonar.cnf.erb'),
    owner   => 'root',
    group   => '999',
    mode    => '0640',
    require => File[$sonar::params::mysql_conf_dir]
  }
  file { "${sonar::install_dir}/mysql_init/user_backup.sql" :
    ensure  => file,
    content => template ('sonar/mysql/user.sql.erb'),
    owner   => 'root',
    group   => '999',
    mode    => '0640',
  }

  ########################
  ## Sonar configuration
  ########################
  file { "${sonar::params::sonar_conf_dir}/sonar.properties" :
    ensure  => file,
    content => template ('sonar/sonar.properties.erb'),
    owner   => 'root',
    group   => '999',
    mode    => '0640',
    require => File[$sonar::params::sonar_conf_dir]
  }

  ########################
  ## Docker compose file
  ########################
  file { "${sonar::install_dir}/docker-compose.yml" :
    ensure  => 'present',
    content => template ('sonar/docker-compose.yml.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
  }

  ########################
  ## Crowd plugin
  ########################
  if $sonar::install_crowd_plugin == true {
    wget::fetch { 'sonar_crowd':
      source_url       => "http://downloads.sonarsource.com/plugins/org/codehaus/sonar-plugins/sonar-crowd-plugin/${sonar::version_crowdin_plugin}/sonar-crowd-plugin-${sonar::version_crowdin_plugin}.jar",
      target_directory => "${sonar::params::extensions_dir}/plugins",
      target_file      => "sonar-crowd-plugin-${sonar::version_crowdin_plugin}.jar",
      require          => File["${sonar::params::extensions_dir}/plugins"],
      notify           => Docker_compose["${sonar::install_dir}/docker-compose.yml"],
    }
  }

  ########################
  ## Sonar eXo Rules
  ########################
  if $sonar::install_exo_rules == true {
    wget::fetch { 'sonar_exo_rules':
      source_url       => "https://repository.exoplatform.org/content/groups/public/org/exoplatform/swf/sonar-exo-rules/${sonar::version_exo_rules}/sonar-exo-rules-${sonar::version_exo_rules}.jar",
      target_directory => "${sonar::params::extensions_dir}/plugins",
      target_file      => "sonar-exo-rules-${sonar::version_exo_rules}.jar",
      require          => File["${sonar::params::extensions_dir}/plugins"],
      notify           => Docker_compose["${sonar::install_dir}/docker-compose.yml"],
    }
  }

  ###########################
  #  Launch the containers
  ###########################
  docker_compose { "${sonar::install_dir}/docker-compose.yml" :
    ensure  => 'present',
    require => [
      Class['docker::compose'],
      File[
        "${sonar::install_dir}/docker-compose.yml",
        "${sonar::params::mysql_conf_dir}/sonar.cnf",
        "${sonar::params::sonar_conf_dir}/sonar.properties",
        "${sonar::install_dir}/mysql_init/user_backup.sql"
      ],
    ],
  }

  ###########################
  #  scripts configuration
  ###########################
  file { "${sonar::install_dir}/bin/_setenv.sh" :
    ensure  => 'present',
    content => template('sonar/bin/_setenv.sh.erb'),
    owner   => 'root',
    group   => 'sonar',
    mode    => '0750',
    require => [File["${sonar::install_dir}/bin"]]
  }

}
