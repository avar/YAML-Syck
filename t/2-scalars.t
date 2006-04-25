use t::TestYAML tests => 25; 

ok(YAML::Syck->VERSION);

is(Dump(42),    "--- 42\n");
is(Load("--- 42\n"), 42);

is(Dump(\42),    "--- !perl/ref: \n=: 42\n");
is(${Load("--- !perl/ref: \n=: 42\n")}, 42);

my $x;
$x = \$x;
is(Dump($x),     "--- &1 !perl/ref: \n=: *1\n");
is(Dump(sub{}),  "--- !perl/code: '{ \"DUMMY\" }'\n");

is(Dump(undef), "--- ~\n");
is(Dump('~'), "--- \'~\'\n");
is(Dump('a:'), "--- \"a:\"\n");
is(Dump('a: '), "--- \"a: \"\n");
is(Dump('a '), "--- \"a \"\n");
is(Dump('a: b'), "--- \"a: b\"\n");
is(Dump('a:b'), "--- a:b\n");
is(Load("--- ~\n"), undef);
is(Load("---\n"), undef);
is(Load("--- ''\n"), '');

my $h = {bar => [qw<baz troz>]};
$h->{foo} = $h->{bar};
is(Dump($h), << '.');
--- 
bar: &1 
  - baz
  - troz
foo: *1
.

my $r; $r = \$r;
is(Dump($r), << '.');
--- &1 !perl/ref: 
=: *1
.
is(Dump(Load(Dump($r))), << '.');
--- &1 !perl/ref: 
=: *1
.

# RT #17223
my $y = YAML::Syck::Load("SID:\n type: fixed\n default: ~\n");
eval { $y->{SID}{default} = 'abc' };
is($y->{SID}{default}, 'abc');

is(Load("--- true\n"), "true");
is(Load("--- false\n"), "false");

$YAML::Syck::ImplicitTyping = $YAML::Syck::ImplicitTyping = 1;

is(Load("--- true\n"), 1);
is(Load("--- false\n"), '');
