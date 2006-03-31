use strict;
use Test;

BEGIN { plan tests => 11 }

require YAML::Syck;
ok(YAML::Syck->VERSION);
YAML::Syck->import;

ok(Dump(42),    "--- 42\n");
ok(Load("--- 42\n"), 42);

ok(Dump(undef), "--- ~\n");
ok(Load("--- ~\n"), undef);
ok(Load("---\n"), undef);
ok(Load("--- ''\n"), '');

ok(Load("--- true\n"), "true");
ok(Load("--- false\n"), "false");

$YAML::Syck::ImplicitTyping = $YAML::Syck::ImplicitTyping = 1;

ok(Load("--- true\n"), 1);
ok(Load("--- false\n"), '');
