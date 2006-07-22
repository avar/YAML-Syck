use strict;

use t::TestYAML tests => 3;
use YAML::Syck qw(Load Dump);

{
   my %cache;
   package Special;
   sub YAML_dump {
       my $self = shift;
       return ($self->{object_id});
   }
   sub YAML_load {
       my $class = shift;
       my $quasi_serialized = shift;
       $cache{$quasi_serialized} ||=
       bless { object_id => $quasi_serialized }, $class;
   }
   sub new {
       my $class = shift;
       my %args = shift;
       $cache{$args{object_id}} ||= bless \%args,$class;
   }
}

my $object = Special->new(object_id => "12345");

is Dump($object), "--- !!perl/hook:Special '12345'\n";

my $clone = Load($object);

is($clone->{object_id}, '12345');

is 0+$object, 0+$clone;
