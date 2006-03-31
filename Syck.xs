#include "perl_syck.h"
#undef YAML_IS_JSON

MODULE = YAML::Syck		PACKAGE = YAML::Syck		

PROTOTYPES: DISABLE

SV *
Load (s)
	char *	s

SV *
Dump (sv)
	SV *	sv
