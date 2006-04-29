use strict;
use t::TestYAML ();
use JSON::Syck;
use Test::More;

plan tests => 2;

$JSON::Syck::SingleQuote = 1;

my $str = "moose ";
my $dump = JSON::Syck::Dump($str);
is $dump, "'moose '";
is JSON::Syck::Load($dump), $str;
