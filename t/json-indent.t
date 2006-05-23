use strict;
use Test::More tests => 1;
use JSON::Syck;

my $str = "foo\nbar\nbaz\n";
my $json = JSON::Syck::Dump({ str => $str });

unlike $json, qr/^  bar/m;
