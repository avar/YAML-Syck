package t::TestYAML;
use strict;
use Test;
use YAML::Syck;

sub import { shift; plan @_ }

*::ok = *ok;
*::is = *ok;
*::Dump = *YAML::Syck::Dump;
*::Load = *YAML::Syck::Load;

#use Test::YAML 0.51 -Base;
#
#$Test::YAML::YAML = 'YAML::Syck';
#Test::YAML->load_yaml_pm;
