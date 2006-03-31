use strict;
use Test::More;
use YAML::Syck;
use Tie::Hash;

plan tests => 1;

my($foo, $bar);
{
    my %h;
    my $rh = \%h;
    %h = (a=>1, b=>'2', c=>3.1415, d=>4);
    bless $rh => 'Tie::StdHash';
    $foo = Dump($rh);
}
{
    my %h;
    my $th = tie %h, 'Tie::StdHash';
    %h = (a=>1, b=>'2', c=>3.1415, d=>4);
    $bar = Dump($th);
}

is $foo, $bar;

