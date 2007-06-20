package YAML::Syck;
use strict;
use vars qw(
    @ISA @EXPORT $VERSION
    $Headless $SortKeys $SingleQuote
    $ImplicitTyping $ImplicitUnicode 
    $UseCode $LoadCode $DumpCode
    $DeparseObject
);
use 5.00307;
use Exporter;

BEGIN {
    $VERSION = '0.90';
    @EXPORT  = qw( Dump Load DumpFile LoadFile );
    @ISA     = qw( Exporter );

    $SortKeys = 1;

    local $@;
    eval {
        require XSLoader;
        XSLoader::load(__PACKAGE__, $VERSION);
        1;
    } or do {
        require DynaLoader;
        push @ISA, 'DynaLoader';
        __PACKAGE__->bootstrap($VERSION);
    };
}

sub __qr_helper {
    if (index($_[0], '(?-xism:') == 0) {
        qr/${\substr($_[0], 8, -1)}/;
    }
    elsif ($_[0] =~ /\A  \(\?  ([xism]+)  -  (?:[xism]*)  : (.*) \)  \z/x) {
        local $@;
        eval "qr/\$2/$1";
    }
    else {
        qr/$_[0]/;
    }
}

sub Dump {
    $#_ ? join('', map { YAML::Syck::DumpYAML($_) } @_)
        : YAML::Syck::DumpYAML($_[0]);
}

sub Load {
    if (wantarray) {
        my ($rv) = YAML::Syck::LoadYAML($_[0]);
        @{$rv};
    }
    else {
        YAML::Syck::LoadYAML($_[0]);
    }
}

sub DumpFile {
    my $file = shift;
    if ( ref($file) and require Scalar::Util and Scalar::Util::openhandle($file) ) {
        if ($#_) {
            print {$file} YAML::Syck::DumpYAML($_) for @_;
        }
        else {
            print {$file} YAML::Syck::DumpYAML($_[0]);
        }
    }
    else {
        local *FH;
        open FH, "> $file" or die "Cannot write to $file: $!";
        if ($#_) {
            print FH YAML::Syck::DumpYAML($_) for @_;
        }
        else {
            print FH YAML::Syck::DumpYAML($_[0]);
        }
        close FH;
    }
}

sub LoadFile {
    my $file = shift;
    if ( ref($file) and require Scalar::Util and Scalar::Util::openhandle($file) ) {
        Load(do { local $/; <$file> });
    }
    else {
        local *FH;
        open FH, "< $file" or die "Cannot read from $file: $!";
        Load(do { local $/; <FH> });
    }
}

1;
