use strict;
use Test::More;

BEGIN { plan tests => 8 }

require YAML::Syck;
ok(YAML::Syck->VERSION);

YAML::Syck->import;
ok(Dump("Hello, world"), "--- Hello, world\n");
ok(Load("--- Hello, world\n"), "Hello, world");

# XXX: Test::Base this?

is(Dump(42),    "--- 42\n", "Dump a number");
is(Load("--- 42\n"), 42,    "Load a number");

is(Dump(undef), "--- ~\n",  "Dump undef");
is(Load("--- ~\n"), undef,  "Load undef");
is(Load("---\n"), undef,  "Load undef");
