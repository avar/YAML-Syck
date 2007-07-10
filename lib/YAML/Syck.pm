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
    $VERSION = '0.94';
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

use constant _QR_MAP => {
    ''   => sub { qr{$_[0]}     }, 
    x    => sub { qr{$_[0]}x    }, 
    i    => sub { qr{$_[0]}i    }, 
    s    => sub { qr{$_[0]}s    }, 
    m    => sub { qr{$_[0]}m    }, 
    ix   => sub { qr{$_[0]}ix   }, 
    sx   => sub { qr{$_[0]}sx   }, 
    mx   => sub { qr{$_[0]}mx   }, 
    si   => sub { qr{$_[0]}si   }, 
    mi   => sub { qr{$_[0]}mi   }, 
    ms   => sub { qr{$_[0]}sm   }, 
    six  => sub { qr{$_[0]}six  }, 
    mix  => sub { qr{$_[0]}mix  }, 
    msx  => sub { qr{$_[0]}msx  }, 
    msi  => sub { qr{$_[0]}msi  }, 
    msix => sub { qr{$_[0]}msix }, 
};

sub __qr_helper {
    if ($_[0] =~ /\A  \(\?  ([ixsm]*)  (?:-  (?:[ixsm]*))?  : (.*) \)  \z/x) {
        my $sub = _QR_MAP->{$1} || _QR_MAP->{''};
        &$sub($2);
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

# NOTE. The code below (_is_openhandle) avoids to require/load
# Scalar::Util unless it is given a ref or glob
# as an argument. That is purposeful, so to avoid
# the need for this dependency unless strictly necessary.
# If that was not the case, Scalar::Util::openhandle could
# be used directly.

sub _is_openhandle {
    my $h = shift;
    if ( ref($h) || ref(\$h) eq 'GLOB' ) {
        require Scalar::Util;
        return Scalar::Util::openhandle($h);
    } else {
        return undef;
    }
}

sub DumpFile {
    my $file = shift;
    if ( _is_openhandle($file) ) {
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
    if ( _is_openhandle($file) ) {
        Load(do { local $/; <$file> });
    }
    else {
        local *FH;
        open FH, "< $file" or die "Cannot read from $file: $!";
        Load(do { local $/; <FH> });
    }
}

1;
