use Test::More tests => 10;

use JSON::Syck qw(Dump);

my @arr1 = sort {$a cmp $b} qw/1 2 54 howdy/;
is(Dump(\@arr1), '[1,2,54,"howdy"]', "cmp sort doesn't coerce numbers into strings");

{
    no warnings "numeric";
    my @arr2 = sort {$a <=> $b} qw/1 2 54 howdy/;
    is(Dump(\@arr2), '["howdy",1,2,54]', "Numeric sort doesn't coerce non-numeric strings into numbers");
}

my @arr54 = ("howdy",1,2,54);
is(Dump(\@arr54), '["howdy",1,2,54]', "Strings are quoted. Numbers are not");

is(Dump('042'),    '"042"', "Ocatls don't get treated as numbers");
is(Dump('0x42'),    '"0x42"', "Hex doesn't get treated as a number");
is(Dump('0.42'),    '"0.42"', "Floats with leading 0 don't get excluded by octal check");
is(Dump('1_000_000'),    '"1_000_000"', "numbers with underscores get quoted.");
is(Dump('1,000,000'),    '"1,000,000"', "numbers with commas get quoted.");
is(Dump('1e+6'),    '"1e+6"', "Scientific notation gets quoted.");
is(Dump('10e+6'),    '"10e+6"', "Scientific notation gets quoted.");


