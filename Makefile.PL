use strict;
use inc::Module::Install 0.48;

name        'YAML-Syck';
all_from    'lib/YAML/Syck.pm';
inc_paths   '.';
c_files     glob("*.c");

can_cc or die "This module requires a C compiler";

sign; WriteAll;
