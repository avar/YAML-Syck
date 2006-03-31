use t::TestYAML tests => 4;

ok(YAML::Syck->VERSION);

is(Dump(bless({}, 'foo')),    "--- !perl/foo {}\n\n");
my $x = Load("--- !perl/foo {a: b}\n");
is(ref($x), 'foo');
is($x->{a}, 'b');
