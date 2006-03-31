/* #define YAML_IS_JSON 1 */
#include "perl_syck.h"

MODULE = YAML::Syck		PACKAGE = YAML::Syck		

PROTOTYPES: DISABLE

SV *
Load (s)
	char *	s

SV *
Dump (sv)
	SV *	sv
