use t::TestYAML tests => 6;

ok(YAML::Syck->VERSION);

is(Dump(bless({}, 'foo')),    "--- !perl/foo {}\n\n");
my $x = Load("--- !perl/foo {a: b}\n");
is(ref($x), 'foo');
is($x->{a}, 'b');

my $y = Load("--- !hs/Foo {a: b}\n");
is(ref($y), 'hs::Foo');
is($y->{a}, 'b');
