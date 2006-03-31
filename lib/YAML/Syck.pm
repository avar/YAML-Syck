package YAML::Syck;
use strict;
use vars qw( @ISA @EXPORT $VERSION );

use 5.003;
use DynaLoader;

$VERSION = '0.13';
@EXPORT  = qw( Dump Load DumpFile LoadFile );
@ISA     = qw( Exporter DynaLoader );

sub DumpFile {
    my $file = shift;
    local *FH;
    open FH, "> $file" or die "Cannot write to $file: $!";
    print FH Dump($_[0]);
}
sub LoadFile {
    my $file = shift;
    local *FH;
    open FH, "< $file" or die "Cannot read from $file: $!";
    Load(do { local $/; <FH> })
}

__PACKAGE__->bootstrap;

1;
