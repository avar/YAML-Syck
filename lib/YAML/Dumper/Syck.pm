package YAML::Dumper::Syck;

use strict;
use constant S => 'YAML::Syck';

sub new { $_[0] }

sub dump {
    my $emitter = S->new_emitter;
    my $out = '';
    S->perl_set_emitter_handler($emitter, $_[1]);
    S->perl_mark_emitter($emitter);
    S->perl_set_output_handler($emitter, $out);
    S->emit($emitter, $_[1]);
    S->emitter_flush($emitter, 0);
    S->free_emitter($emitter);
    return $out;
}

1;
