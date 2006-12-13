use strict;
use warnings;
use Test::More tests => 1;

use JSON::Syck;
my $foo = bless { }, "Foo";
my $bar = bless { foo => $foo }, "Bar";
$foo->{bar} = $bar;

JSON::Syck::Dump($foo);

ok 1, "No segfault";
