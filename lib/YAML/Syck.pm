package YAML::Syck;
use strict;
use vars qw( @ISA @EXPORT $VERSION );

use 5.003;
use DynaLoader;

$VERSION = '0.04';
@EXPORT  = qw(Dump Load);
@ISA     = qw( Exporter DynaLoader );

__PACKAGE__->bootstrap;

1;
