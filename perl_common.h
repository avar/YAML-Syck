#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_grok_oct
#define NEED_grok_hex
#define NEED_grok_number
#define NEED_grok_numeric_radix
#define NEED_newRV_noinc
#include "ppport.h"
#include "ppport_math.h"
#include "ppport_sort.h"

#undef DEBUG /* maybe defined in perl.h */
#include <syck.h>

#ifndef newSVpvn_share
#define newSVpvn_share(x, y, z) newSVpvn(x, y)
#endif

/*
#undef ASSERT
#include "Storable.xs"
*/

struct emitter_xtra {
    SV* port;
    char* tag;
};

SV* perl_syck_lookup_sym( SyckParser *p, SYMID v) {
    SV *obj = &PL_sv_undef;
    syck_lookup_sym(p, v, (char **)&obj);
    return obj;
}

#define CHECK_UTF8 \
    if (p->bonus && is_utf8_string((U8*)n->data.str->ptr, n->data.str->len)) \
        SvUTF8_on(sv);

void perl_syck_mark_emitter(SyckEmitter *e, SV *sv) {
    if (syck_emitter_mark_node(e, (st_data_t)sv) == 0) {
        return;
    }

    if (SvROK(sv)) {
        perl_syck_mark_emitter(e, SvRV(sv));
        return;
    }

    switch (SvTYPE(sv)) {
        case SVt_PVAV: {
            I32 len, i;
            len = av_len((AV*)sv) + 1;
            for (i = 0; i < len; i++) {
                SV** sav = av_fetch((AV*)sv, i, 0);
                perl_syck_mark_emitter( e, *sav );
            }
            break;
        }
        case SVt_PVHV: {
            I32 len, i;
#ifdef HAS_RESTRICTED_HASHES
            len = HvTOTALKEYS((HV*)sv);
#else
            len = HvKEYS((HV*)sv);
#endif
            hv_iterinit((HV*)sv);
            for (i = 0; i < len; i++) {
#ifdef HV_ITERNEXT_WANTPLACEHOLDERS
                HE *he = hv_iternext_flags((HV*)sv, HV_ITERNEXT_WANTPLACEHOLDERS);
#else
                HE *he = hv_iternext((HV*)sv);
#endif
                I32 keylen;
                SV *val = hv_iterval((HV*)sv, he);
                perl_syck_mark_emitter( e, val );
            }
            break;
        }
    }
}

SyckNode * perl_syck_bad_anchor_handler(SyckParser *p, char *a) {
    croak(form( "%s parser (line %d, column %d): Unsupported self-recursive anchor *%s", 
        "Syck",
        p->linect + 1,
        p->cursor - p->lineptr,
        a ));
    /*
    SyckNode *badanc = syck_new_map(
        (SYMID)newSVpvn_share("name", 4, 0),
        (SYMID)newSVpvn_share(a, strlen(a), 0)
    );
    badanc->type_id = syck_strndup( "perl:YAML::Syck::BadAlias", 25 );
    return badanc;
    */
}

void perl_syck_error_handler(SyckParser *p, char *msg) {
    croak(form( "%s parser (line %d, column %d): %s", 
        "Syck",
        p->linect + 1,
        p->cursor - p->lineptr,
        msg ));
}

void perl_syck_output_handler(SyckEmitter *e, char *str, long len) {
    struct emitter_xtra *bonus = (struct emitter_xtra *)e->bonus;
    sv_catpvn_nomg(bonus->port, str, len);
}

