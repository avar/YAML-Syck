use strict;
use lib '.';
use inc::Module::Install;

name            'YAML-Syck';
all_from        'lib/YAML/Syck.pm';
cc_inc_paths    '.';
cc_files        (glob("*.c"), (-e 'Syck.c' ? () : 'Syck.c'));

# cc_optimize_flags '-g3';

can_cc or die "This module requires a C compiler";

sign; WriteAll;
