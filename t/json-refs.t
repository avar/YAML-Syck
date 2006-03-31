use strict;
use JSON::Syck;
use Test::More;

plan tests => 2;

my $str = "foo";
my $r = { foo => \$str, bar => sub { return "bar" } };

local $SIG{__WARN__} = sub { 1 };

my $dump = JSON::Syck::Dump $r;
like $dump, qr/"bar":""/;
unlike $dump, qr[!perl/ref];


