use strict;
use Test::More tests => 1;

use JSON::Syck;

my $dat = JSON::Syck::Dump({ foo => undef });
like $dat, qr/null/;

