use strict;
use Test;

BEGIN { plan tests => 8 }

require YAML::Syck;
ok(YAML::Syck->VERSION);
YAML::Syck->import;

ok(Dump(42),    "--- 42\n");
ok(Load("--- 42\n"), 42);

ok(Dump(undef), "--- ~\n");
ok(Load("--- ~\n"), undef);
ok(Load("---\n"), undef);
