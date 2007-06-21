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

use constant _QR_MAP => {
    ''   => sub { qr/$_[0]/     },
    i    => sub { qr/$_[0]/i    },
    x    => sub { qr/$_[0]/x    },
    ix   => sub { qr/$_[0]/ix   },
    s    => sub { qr/$_[0]/s    },
    is   => sub { qr/$_[0]/is   },
    xs   => sub { qr/$_[0]/xs   },
    ixs  => sub { qr/$_[0]/ixs  },
    m    => sub { qr/$_[0]/m    },
    im   => sub { qr/$_[0]/im   },
    xm   => sub { qr/$_[0]/xm   },
    ixm  => sub { qr/$_[0]/ixm  },
    sm   => sub { qr/$_[0]/sm   },
    ism  => sub { qr/$_[0]/ism  },
    xsm  => sub { qr/$_[0]/xsm  },
    ixsm => sub { qr/$_[0]/ixsm },
};

sub __qr_helper {
    if ($_[0] =~ /\A  \(\?  ([ixsm]*)  -  (?:[ixsm]*)  : (.*) \)  \z/x) {
        _QR_MAP->{$1}->($2);
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
