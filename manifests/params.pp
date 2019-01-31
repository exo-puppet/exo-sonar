# parameters
class sonar::params {
  $mysql_data_dir = "${sonar::base_data_dir}/mysql"
  $mysql_conf_dir = "${sonar::install_dir}/mysql"
  $mysql_log_dir  = "${sonar::log_dir}/mysql"
  $sonar_conf_dir = "${sonar::install_dir}/conf"

  $data_dir       = "${sonar::base_data_dir}/data"
  $extensions_dir = "${sonar::base_data_dir}/extensions"
}
