#!/sw/bin/perl -w

use strict;
use YAML::Syck;
use Test::More tests => 4;

SKIP: {
    eval { require Devel::Leak }
      or skip( "Devel::Leak not installed", 4 );

    # check if arrays leak

    my $yaml = q{---
blah
};

    require Symbol;
    my $handle = Symbol::gensym();
    my $diff;

    # For some reason we have to do a full test run of this loop and the
    # Devel::Leak test before it's stable.  The first time diff ends up
    # being -2.  This is probably Devel::Leak wonkiness.
    my $before = Devel::Leak::NoteSV($handle);
    foreach ( 1 .. 100 ) {
        Load($yaml);
    }

    $diff = Devel::Leak::NoteSV($handle) - $before;

    $before = Devel::Leak::NoteSV($handle);
    foreach ( 1 .. 100 ) {
        Load($yaml);
    }

    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - array" );

    # Check if hashess leak
    $yaml = q{---
result: test
};

    $before = Devel::Leak::NoteSV($handle);
    foreach ( 1 .. 100 ) {
        Load($yaml);
    }

    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - hash" );

    $before = Devel::Leak::NoteSV($handle);
    $yaml   = q{---
a: b
c:
 - d
 - e
!
};

    eval { Load($yaml) };
    ok( $@, "Load failed (expected)" );

    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - Load failure" );

}
