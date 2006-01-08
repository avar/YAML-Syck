use strict;
use Test;

BEGIN { plan tests => 4 }

require YAML::Syck;
ok(YAML::Syck->VERSION);
YAML::Syck->import;

ok(Dump(bless({}, 'foo')),    "--- !perl/foo {}\n\n");
my $x = Load("--- !perl/foo {a: b}\n");
ok(ref($x), 'foo');
ok($x->{a}, 'b');
