#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#undef DEBUG /* maybe defined in perl.h */
#include <syck.h>

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

SYMID perl_syck_parser_handler(SyckParser *p, SyckNode *n) {
    SV *sv;
    AV *seq;
    HV *map;
    long i;

    switch (n->kind) {
        case syck_str_kind:
            if (n->type_id == NULL || strcmp( n->type_id, "str" ) == 0 ) {
                sv = newSVpvn(n->data.str->ptr, n->data.str->len);
            } else if (strcmp( n->type_id, "null" ) == 0 ) {
                sv = &PL_sv_undef;
            } else {
                sv = newSVpvn(n->data.str->ptr, n->data.str->len);
                /* croak("unknown node type: %s", n->type_id); */
            }
        break;

        case syck_seq_kind:
            seq = newAV();
            for (i = 0; i < n->data.list->idx; i++) {
                av_push(seq, perl_syck_lookup_sym(p, syck_seq_read(n, i) ));
            }
            sv = newRV_noinc((SV*)seq);
            if (n->type_id) {
                sv_bless(sv, gv_stashpv(n->type_id + 6, TRUE));
            }
        break;

        case syck_map_kind:
            map = newHV();
            for (i = 0; i < n->data.pairs->idx; i++) {
                hv_store_ent(
                    map,
                    perl_syck_lookup_sym(p, syck_map_read(n, map_key, i) ),
                    perl_syck_lookup_sym(p, syck_map_read(n, map_value, i) ),
                    0
                );
            }
            sv = newRV_noinc((SV*)map);
            if (n->type_id) {
                sv_bless(sv, gv_stashpv(n->type_id + 5, TRUE));
            }
        break;
    }
    return syck_add_sym(p, (char *)sv);
}

void perl_syck_mark_emitter(SyckEmitter *e) {
    return;
}

static SV * Load(char *s) {
    SV *obj;
    SYMID v;
    SyckParser *parser = syck_new_parser();
    syck_parser_str_auto(parser, s, NULL);
    syck_parser_handler(parser, perl_syck_parser_handler);
    syck_parser_error_handler(parser, NULL);
    syck_parser_implicit_typing(parser, 1);
    syck_parser_taguri_expansion(parser, 0);
    v = syck_parse(parser);
    syck_lookup_sym(parser, v, (char **)&obj);
    syck_free_parser(parser);
    return obj;
}

void perl_syck_output_handler(SyckEmitter *e, char *str, long len) {
    struct emitter_xtra *bonus = (struct emitter_xtra *)e->bonus;
    sv_catpvn_nomg(bonus->port, str, len);
}

void perl_syck_emitter_handler(SyckEmitter *e, st_data_t data) {
    I32  len, i;
    SV*  sv = (SV*)data;
    struct emitter_xtra *bonus = (struct emitter_xtra *)e->bonus;
    char* tag = bonus->tag;
    char* ref = NULL;

    if (sv == &PL_sv_undef) {
        return syck_emit_scalar(e, "string", scalar_none, 0, 0, 0, "~", 1);
    }
    
#define OBJECT_TAG     "tag:perl:"
    
    if (SvMAGICAL(sv)) {
        mg_get(sv);
    }

    if (sv_isobject(sv)) {
        ref = savepv(sv_reftype(SvRV(sv), TRUE));
        *tag = '\0';
        strcat(tag, OBJECT_TAG);
        switch (SvTYPE(SvRV(sv))) {
            case SVt_PVAV: { strcat(tag, "@"); break; }
            case SVt_RV:   { strcat(tag, "$"); break; }
            case SVt_PVCV: { strcat(tag, "code"); break; }
            case SVt_PVGV: { strcat(tag, "glob"); break; }
        }
        strcat(tag, ref);
    }

#define OBJOF(a) (*tag ? tag : a)
    switch (SvTYPE(sv)) {
        case SVt_NULL: { return; }
        case SVt_PV:
        case SVt_PVIV:
        case SVt_PVNV: { /* XXX !SvROK(sv) XXX */
            syck_emit_scalar(e, OBJOF("string"), scalar_none, 0, 0, 0, SvPVX(sv), SvCUR(sv));
            break;
        }
        case SVt_IV:
        case SVt_NV:
        case SVt_PVMG:
        case SVt_PVBM:
        case SVt_PVLV: {
            syck_emit_scalar(e, OBJOF("string"), scalar_none, 0, 0, 0, SvPV_nolen(sv), sv_len(sv));
            break;
        }
        case SVt_RV: {
            perl_syck_emitter_handler(e, (st_data_t)SvRV(sv));
            break;
        }
        case SVt_PVAV: {
            syck_emit_seq(e, OBJOF("array"), seq_none);
            *tag = '\0';
            len = av_len((AV*)sv) + 1;
            for (i = 0; i < len; i++) {
                SV** sav = av_fetch((AV*)sv, i, 0);
                syck_emit_item( e, (st_data_t)(*sav) );
            }
            syck_emit_end(e);
            return;
        }
        case SVt_PVHV: {
            syck_emit_map(e, OBJOF("hash"), map_none);
            *tag = '\0';
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
                SV *key = hv_iterkeysv(he);
                SV *val = hv_iterval((HV*)sv, he);
                syck_emit_item( e, (st_data_t)key );
                syck_emit_item( e, (st_data_t)val );
            }
            syck_emit_end(e);
            return;
        }
        case SVt_PVCV: {
            /* XXX TODO XXX */
            syck_emit_scalar(e, OBJOF("string"), scalar_none, 0, 0, 0, SvPV_nolen(sv), sv_len(sv));
            break;
        }
        case SVt_PVGV:
        case SVt_PVFM: {
            /* XXX TODO XXX */
            syck_emit_scalar(e, OBJOF("string"), scalar_none, 0, 0, 0, SvPV_nolen(sv), sv_len(sv));
            break;
        }
        case SVt_PVIO: {
            syck_emit_scalar(e, OBJOF("string"), scalar_none, 0, 0, 0, SvPV_nolen(sv), sv_len(sv));
            break;
        }
    }
cleanup:
    *tag = '\0';
}

SV* Dump(SV *sv) {
    struct emitter_xtra *bonus;
    SV* out = newSVpvn("", 0);
    SyckEmitter *emitter = syck_new_emitter();

    bonus = emitter->bonus = S_ALLOC_N(struct emitter_xtra, 1);
    bonus->port = out;
    Newz(801, bonus->tag, 512, char);

    syck_emitter_handler( emitter, perl_syck_emitter_handler );
    syck_output_handler( emitter, perl_syck_output_handler );

    perl_syck_mark_emitter( emitter );
    syck_emit( emitter, (st_data_t)sv );
    syck_emitter_flush( emitter, 0 );
    syck_free_emitter( emitter );
    Safefree(bonus->tag);

    return out;
}

MODULE = YAML::Syck		PACKAGE = YAML::Syck		

PROTOTYPES: DISABLE

SV *
Load (s)
	char *	s

SV *
Dump (sv)
	SV *	sv
