package t::TestYAML;
use Test::YAML 0.51 -Base;

$Test::YAML::YAML = 'YAML::Syck';
Test::YAML->load_yaml_pm;
