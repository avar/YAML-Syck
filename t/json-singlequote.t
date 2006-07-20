use strict;
use warnings;

use JSON::Syck;
use Test::More tests => 2;

$JSON::Syck::SingleQuote = 1;

my $dump;

$dump = JSON::Syck::Dump(q{Some string});
is($dump, q{'Some string'});

#Test escaping
my $thing = q{I'm sorry, Dave.};
$dump = JSON::Syck::Dump($thing);
is(JSON::Syck::Load($dump), $thing);
