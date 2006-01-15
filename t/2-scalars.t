use t::TestYAML tests => 14; 

ok(YAML::Syck->VERSION);

is(Dump(42),    "--- 42\n");
is(Load("--- 42\n"), 42);

is(Dump(\42),    "--- !perl/ref: \n=: 42\n");
is(${Load("--- !perl/ref: \n=: 42\n")}, 42);

my $x;
$x = \$x;
is(Dump($x),     "--- &1 !perl/ref: \n=: *1\n");

is(Dump(undef), "--- ~\n");
is(Load("--- ~\n"), undef);
is(Load("---\n"), undef);
is(Load("--- ''\n"), '');

is(Load("--- true\n"), "true");
is(Load("--- false\n"), "false");

$YAML::Syck::ImplicitTyping = $YAML::Syck::ImplicitTyping = 1;

is(Load("--- true\n"), 1);
is(Load("--- false\n"), '');
