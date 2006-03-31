use strict;
use JSON::Syck;
use Test::More tests => 2;

my $data = JSON::Syck::Load('{"i":{"cid":"123","sid":"123","c":"","v":"2.0","m":"h01iSTI5","up":""},"e":{"m":"click","x":109,"y":71,"dt":1850,"v":0,"t":-1,"c":-1}}');

is $data->{e}->{t}, -1;
is $data->{e}->{c}, -1;
