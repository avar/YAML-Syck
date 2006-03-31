use strict;
use Test;

BEGIN { plan tests => 3 }

require YAML::Syck;
ok(YAML::Syck->VERSION);
YAML::Syck->import;

ok(Dump("Hello, world"), "--- Hello, world\n");
ok(Load("--- Hello, world\n"), "Hello, world");

