use strict;
use Test::More;
use YAML::Syck;
use Tie::Hash;
use Storable qw/freeze thaw/;
use Data::Dumper;

plan tests => 3;

my $bref = bless \eval{my $scalar = 'YAML::Syck' }, 'foo';
my $bref2bref = bless \$bref, 'bar';

my $dd =  Dumper $bref2bref;
my $edd;
{
    no strict 'vars';
    $edd = eval $dd;
}
is Dumper($edd),                     $dd, 'Data::Dumper';
is Dumper(thaw(freeze($bref2bref))), $dd, 'Storable';
is Dumper(Load(Dump($bref2bref))),   $dd, 'YAML::Syck'
