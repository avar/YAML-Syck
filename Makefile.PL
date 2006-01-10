use strict;
use lib '.';
use inc::Module::Install;

name        'YAML-Syck';
all_from    'lib/YAML/Syck.pm';
inc_paths   '.';
c_files     (glob("*.c"), (-e 'Syck.c' ? () : 'Syck.c'));
#optimize_flags '-g3';

can_cc or die "This module requires a C compiler";

sign; WriteAll;
