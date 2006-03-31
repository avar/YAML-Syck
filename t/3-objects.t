use t::TestYAML tests => 7;

ok(YAML::Syck->VERSION);

is(Dump(bless({}, 'foo')),    "--- !perl/foo {}\n\n");
my $x = Load("--- !perl/foo {a: b}\n");
is(ref($x), 'foo');
is($x->{a}, 'b');

my $y = Load("--- !hs/Foo {a: b}\n");
is(ref($y), 'hs::Foo');
is($y->{a}, 'b');

$YAML::Syck::SortKeys = $YAML::Syck::SortKeys = 1;
is(Dump(bless({1..10}, 'foo')),  "--- !perl/foo \n1: 2\n3: 4\n5: 6\n7: 8\n9: 10\n");
