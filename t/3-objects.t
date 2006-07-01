use t::TestYAML tests => 19;

ok(YAML::Syck->VERSION);

is(Dump(bless({}, 'foo')),    "--- !!perl/hash:foo {}\n\n");
my $w = Load("--- !!perl/hash:foo {a: b}\n");
is(ref($w), 'foo');
is($w->{a}, 'b');

my $x = Load("--- !perl/foo {a: b}\n");
is(ref($x), 'foo');
is($x->{a}, 'b');

my $y = Load("--- !hs/Foo {a: b}\n");
is(ref($y), 'hs::Foo');
is($y->{a}, 'b');

my $z = Load("--- !haskell.org/Foo {a: b}\n");
is(ref($z), 'haskell.org::Foo');
is($z->{a}, 'b');

my $a = Load("--- !haskell.org/^Foo {a: b}\n");
is(ref($a), 'haskell.org::Foo');
is($a->{a}, 'b');

is(Dump(bless({1..10}, 'foo')),  "--- !!perl/hash:foo \n1: 2\n3: 4\n5: 6\n7: 8\n9: 10\n");

$YAML::Syck::UseCode = 1;

{
	my $hash = Load(Dump(bless({1 .. 4}, "code")));
	is(ref($hash), "code", "blessed to code");
	is(eval { $hash->{1} }, 2, "it's a hash");
}

{
	my $sub = Load(Dump(bless(sub { 42 }, "foobar")));
	is(ref($sub), "foobar", "blessed to foobar");
	is(eval { $sub->() }, 42, "it's a CODE");
}

{
	my $sub = Load(Dump(bless(sub { 42 }, "code")));
	is(ref($sub), "code", "blessed to code");
	is(eval { $sub->() }, 42, "it's a CODE");
}

