use strict;
use Test::More tests => 1;
use YAML::Syck;

use Tie::IxHash;
tie( my %tied, "Tie::IxHash" );
%tied = ("howdy" => { a => 1 } );

TODO: {
    local $TODO = "Tie::IxHash dumps";
    isnt(YAML::Syck::Dump( \%tied ), "--- {}\n\n", "Correct output from Dump");
}
