#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <syck.h>

#ifdef HvPLACEHOLDERS
#define HAS_RESTRICTED_HASHES
#endif

typedef SV* Perl_Scalar;

Perl_Scalar syck_perl_lookup_sym( SyckParser *p, SYMID v) {
    SV *obj = &PL_sv_undef;
    syck_lookup_sym(p, v, (char **)&obj);
    return obj;
}

SYMID syck_perl_parser_handler(SyckParser *p, SyckNode *n) {
    SV *sv;
    AV *seq;
    HV *map;
    long i;

    switch (n->kind) {
        case syck_str_kind:
            sv = newSVpvn(n->data.str->ptr, n->data.str->len);
        break;

        case syck_seq_kind:
            seq = newAV();
            for (i = 0; i < n->data.list->idx; i++) {
                av_push(seq, syck_perl_lookup_sym(p, syck_seq_read(n, i) ));
            }
            sv = newRV_inc((SV*)seq);
        break;

        case syck_map_kind:
            map = newHV();
            for (i = 0; i < n->data.pairs->idx; i++) {
                hv_store_ent(
                    map,
                    syck_perl_lookup_sym(p, syck_map_read(n, map_key, i) ),
                    syck_perl_lookup_sym(p, syck_map_read(n, map_value, i) ),
                    0
                );
            }
            sv = newRV_inc((SV*)map);
        break;
    }
    return syck_add_sym(p, (char *)sv);
}

void syck_perl_set_parser_handler( SyckParser *p ) {
    syck_parser_handler( p, syck_perl_parser_handler );
}

struct emitter_xtra {
    SV* this;
    SV* output;
    int id;
};

void syck_perl_emitter_handler(SyckEmitter *e, st_data_t data) {
    I32  len, i;
    SV*  sv = (SV*)data;
    struct emitter_xtra *bonus = (struct emitter_xtra *)e->bonus;

    switch (SvTYPE(sv)) {
        case SVt_NULL: { return; }
        case SVt_PV:
        case SVt_PVIV:
        case SVt_PVNV: { /* XXX !SvROK(sv) XXX */
            bonus->id++;
            return syck_emit_scalar(e, "string", scalar_none, 0, 0, 0, SvPVX(sv), SvCUR(sv));
        }
        case SVt_IV:
        case SVt_NV:
        case SVt_PVMG:
        case SVt_PVBM:
        case SVt_PVLV: {
            bonus->id++;
            return syck_emit_scalar(e, "string", scalar_none, 0, 0, 0, SvPV_nolen(sv), sv_len(sv));
        }
        case SVt_RV: {
            return syck_perl_emitter_handler(e, (st_data_t)SvRV(sv));
        }
        case SVt_PVAV: {
            syck_emit_seq(e, "array", seq_none);
            len = av_len((AV*)sv) + 1;
            for (i = 0; i < len; i++) {
                SV** sav = av_fetch((AV*)sv, i, 0);
                syck_emit_item( e, (st_data_t)(*sav) );
            }
            syck_emit_end(e);
            bonus->id++;
            return;
        }
        case SVt_PVHV: {
            syck_emit_map(e, "hash", map_none);
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
            bonus->id++;
            return;
        }
        case SVt_PVCV: {
            /* XXX TODO XXX */
            return syck_emit_scalar(e, "string", scalar_none, 0, 0, 0, SvPV_nolen(sv), sv_len(sv));
        }
        case SVt_PVGV:
        case SVt_PVFM: {
            /* XXX TODO XXX */
            return syck_emit_scalar(e, "string", scalar_none, 0, 0, 0, SvPV_nolen(sv), sv_len(sv));
        }
        case SVt_PVIO: {
            return syck_emit_scalar(e, "string", scalar_none, 0, 0, 0, SvPV_nolen(sv), sv_len(sv));
        }
    }
}

void syck_perl_output_handler(SyckEmitter *e, char *str, long len) {
    struct emitter_xtra *bonus = (struct emitter_xtra *)e->bonus;
    sv_catpvn_nomg(bonus->output, str, len);
}

void syck_perl_set_output_handler(SyckEmitter *e, Perl_Scalar sv) {
    struct emitter_xtra *bonus = (struct emitter_xtra *)e->bonus;
    bonus->id = 1;
    bonus->output = sv;
    syck_output_handler(e, syck_perl_output_handler);
}

void syck_perl_mark_emitter(SyckEmitter *e) {
    struct emitter_xtra *bonus = (struct emitter_xtra *)e->bonus;
    I32  len, i;
    SV* sv = bonus->this;

    switch (SvTYPE(sv)) {
        case SVt_PVAV: {
            syck_emit_seq(e, "array", seq_none);
            len = av_len((AV*)sv) + 1;
            for (i = 0; i < len; i++) {
                SV** sav = av_fetch((AV*)sv, i, 0);
                bonus->this = *sav;
                syck_emitter_mark_node(e, bonus->id++);
            }
            bonus->id++;
            return;
        }
        case SVt_PVHV: {
            syck_emit_map(e, "hash", map_none);
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
                SV *key = hv_iterkeysv(he);
                SV *val = hv_iterval((HV*)sv, he);
                bonus->this = key;
                syck_emitter_mark_node(e, bonus->id++);
                bonus->this = val;
                syck_emitter_mark_node(e, bonus->id++);
            }
            syck_emit_end(e);
            bonus->id++;
            return;
        }
        default: {
            syck_emitter_mark_node(e, bonus->id++);
        }
    }
}

void syck_perl_set_emitter_handler( SyckEmitter *e, SV* this ) {
    struct emitter_xtra *bonus;
    e->bonus = S_ALLOC_N(struct emitter_xtra, 1);
    bonus = (struct emitter_xtra *)e->bonus;
    bonus->id = 1;
    bonus->this = this;
    syck_emitter_handler( e, syck_perl_emitter_handler );
}
