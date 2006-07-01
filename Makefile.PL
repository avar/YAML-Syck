use strict;
use lib '.';
use inc::Module::Install;

print << '_';

*** WARNING ***

This release breaks compatability with versions earlier than version 0.60 of
YAML::Syck and YAML.pm when serializing blessed references.

See the COMPATABILITY file for more information.

_

if (!is_admin()) {
    exit() unless prompt("Continue installing YAML.pm?", 'y') =~ /^y/i;
}

name            'YAML-Syck';
all_from        'lib/YAML/Syck.pm';
cc_inc_paths    '.';
cc_files        (glob("*.c"), (-e 'Syck.c' ? () : 'Syck.c'));

# cc_optimize_flags '-g3';

can_cc or die "This module requires a C compiler";

include_deps 'Test::More';
build_requires 'Devel::Leak' if defined $ENV{'AUTOMATED_TESTING'};
sign; WriteAll;
