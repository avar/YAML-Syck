package YAML::Loader::Syck;

use strict;
use constant S => 'YAML::Syck';

sub new { $_[0] }

sub load {
    my $parser = S->new_parser;
    S->parser_str($parser, $_[1], length($_[1]), undef);
    S->perl_set_parser_handler($parser);
    S->parser_error_handler($parser, undef);
    S->parser_implicit_typing($parser, 1);
    S->parser_taguri_expansion($parser, 0);
    my $v = S->parse($parser);
    my $obj = S->perl_lookup_sym($parser, $v);
    S->free_parser($parser);
    return $obj;
}

1;
