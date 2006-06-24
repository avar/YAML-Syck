/* Implementation-specific variables */
#undef PACKAGE_NAME
#undef NULL_LITERAL
#undef NULL_LITERAL_LENGTH
#undef SCALAR_NUMBER
#undef SCALAR_STRING
#undef SCALAR_QUOTED
#undef SCALAR_UTF8
#undef SEQ_NONE
#undef MAP_NONE
#undef COND_FOLD
#undef TYPE_IS_NULL
#undef OBJOF
#undef PERL_SYCK_PARSER_HANDLER
#undef PERL_SYCK_EMITTER_HANDLER
#undef PERL_SYCK_INDENT_LEVEL

#ifdef YAML_IS_JSON
#  define PACKAGE_NAME  "JSON::Syck"
#  define NULL_LITERAL  "null"
#  define NULL_LITERAL_LENGTH 4
#  define SCALAR_NUMBER scalar_none
char json_quote_char = '"';
static enum scalar_style json_quote_style = scalar_2quote;
#  define SCALAR_STRING json_quote_style
#  define SCALAR_QUOTED json_quote_style
#  define SCALAR_UTF8   scalar_fold
#  define SEQ_NONE      seq_inline
#  define MAP_NONE      map_inline
#  define COND_FOLD(x)  TRUE
#  define TYPE_IS_NULL(x) ((x == NULL) || strnEQ( x, "str", 3 ))
#  define OBJOF(a)        (a)
#  define PERL_SYCK_PARSER_HANDLER json_syck_parser_handler
#  define PERL_SYCK_EMITTER_HANDLER json_syck_emitter_handler
#  define PERL_SYCK_INDENT_LEVEL 0
#else
#  define PACKAGE_NAME  "YAML::Syck"
#  define REF_LITERAL  "="
#  define REF_LITERAL_LENGTH 1
#  define NULL_LITERAL  "~"
#  define NULL_LITERAL_LENGTH 1
#  define SCALAR_NUMBER scalar_none
#  define SCALAR_STRING scalar_none
#  define SCALAR_QUOTED scalar_1quote
#  define SCALAR_UTF8   scalar_fold
#  define SEQ_NONE      seq_none
#  define MAP_NONE      map_none
#ifdef SvUTF8
#  define COND_FOLD(x)  (SvUTF8(sv))
#else
#  define COND_FOLD(x)  (0)
#endif
#  define TYPE_IS_NULL(x) (x == NULL)
#  define OBJOF(a)        (*tag ? tag : a)
#  define PERL_SYCK_PARSER_HANDLER yaml_syck_parser_handler
#  define PERL_SYCK_EMITTER_HANDLER yaml_syck_emitter_handler
#  define PERL_SYCK_INDENT_LEVEL 2
#endif

#define TRACK_OBJECT(sv) (av_push(((struct parser_xtra *)p->bonus)->objects, sv))
#define USE_OBJECT(sv) (SvREFCNT_inc(sv))

SYMID
#ifdef YAML_IS_JSON
json_syck_parser_handler
#else
yaml_syck_parser_handler
#endif
(SyckParser *p, SyckNode *n) {
    SV *sv;
    AV *seq;
    HV *map;
    long i;
    switch (n->kind) {
        case syck_str_kind:
            if (TYPE_IS_NULL(n->type_id)) {
                if (strnEQ( n->data.str->ptr, NULL_LITERAL, 1+NULL_LITERAL_LENGTH)
                    && (n->data.str->style == scalar_plain)) {
                    sv = newSV(0);
                } else {
                    sv = newSVpvn(n->data.str->ptr, n->data.str->len);
                    CHECK_UTF8;
                }
            } else if (strEQ( n->type_id, "str" )) {
                sv = newSVpvn(n->data.str->ptr, n->data.str->len);
                CHECK_UTF8;
            } else if (strEQ( n->type_id, "null" )) {
                sv = newSV(0);
            } else if (strEQ( n->type_id, "bool#yes" )) {
                sv = newSVsv(&PL_sv_yes);
            } else if (strEQ( n->type_id, "bool#no" )) {
                sv = newSVsv(&PL_sv_no);
            } else if (strEQ( n->type_id, "default" )) {
                sv = newSVpvn(n->data.str->ptr, n->data.str->len);
                CHECK_UTF8;
            } else if (strEQ( n->type_id, "float#base60" )) {
                char *ptr, *end;
                UV sixty = 1;
                NV total = 0.0;
                syck_str_blow_away_commas( n );
                ptr = n->data.str->ptr;
                end = n->data.str->ptr + n->data.str->len;
                while ( end > ptr )
                {
                    NV bnum = 0;
                    char *colon = end - 1;
                    while ( colon >= ptr && *colon != ':' )
                    {
                        colon--;
                    }
                    if ( *colon == ':' ) *colon = '\0';

                    bnum = strtod( colon + 1, NULL );
                    total += bnum * sixty;
                    sixty *= 60;
                    end = colon;
                }
                sv = newSVnv(total);
#ifdef NV_NAN
            } else if (strEQ( n->type_id, "float#nan" )) {
                sv = newSVnv(NV_NAN);
#endif
#ifdef NV_INF
            } else if (strEQ( n->type_id, "float#inf" )) {
                sv = newSVnv(NV_INF);
            } else if (strEQ( n->type_id, "float#neginf" )) {
                sv = newSVnv(-NV_INF);
#endif
            } else if (strnEQ( n->type_id, "float", 5 )) {
                NV f;
                syck_str_blow_away_commas( n );
                f = strtod( n->data.str->ptr, NULL );
                sv = newSVnv( f );
            } else if (strEQ( n->type_id, "int#base60" )) {
                char *ptr, *end;
                UV sixty = 1;
                UV total = 0;
                syck_str_blow_away_commas( n );
                ptr = n->data.str->ptr;
                end = n->data.str->ptr + n->data.str->len;
                while ( end > ptr )
                {
                    long bnum = 0;
                    char *colon = end - 1;
                    while ( colon >= ptr && *colon != ':' )
                    {
                        colon--;
                    }
                    if ( *colon == ':' ) *colon = '\0';

                    bnum = strtol( colon + 1, NULL, 10 );
                    total += bnum * sixty;
                    sixty *= 60;
                    end = colon;
                }
                sv = newSVuv(total);
            } else if (strEQ( n->type_id, "int#hex" )) {
                I32 flags = 0;
                STRLEN len = n->data.str->len;
                syck_str_blow_away_commas( n );
                sv = newSVuv( grok_hex( n->data.str->ptr, &len, &flags, NULL) );
            } else if (strEQ( n->type_id, "int#oct" )) {
                I32 flags = 0;
                STRLEN len = n->data.str->len;
                syck_str_blow_away_commas( n );
                sv = newSVuv( grok_oct( n->data.str->ptr, &len, &flags, NULL) );
            } else if (strnEQ( n->type_id, "int", 3 )) {
                UV uv = 0;
                syck_str_blow_away_commas( n );
                if (grok_number( n->data.str->ptr, n->data.str->len, &uv) & IS_NUMBER_NEG) {
                    sv = newSViv(-uv);
                }
                else {
                    sv = newSVuv(uv);
                }
#ifndef YAML_IS_JSON
            } else if (strnEQ( n->data.str->ptr, REF_LITERAL, 1+REF_LITERAL_LENGTH)) {
                /* type tag in a scalar ref */
                char *lang = strtok(n->type_id, "/:");
                char *type = strtok(NULL, "");

                if (lang == NULL || (strEQ(lang, "perl"))) {
                    sv = newSVpv(type, 0);
                } else {
                    sv = newSVpv(form("%s::%s", lang, type), 0);
                }
#endif
            } else {
                /* croak("unknown node type: %s", n->type_id); */
                sv = newSVpvn(n->data.str->ptr, n->data.str->len);
                CHECK_UTF8;
            }
        break;

        case syck_seq_kind:
            seq = newAV();
            for (i = 0; i < n->data.list->idx; i++) {
                SV *a = perl_syck_lookup_sym(p, syck_seq_read(n, i));
                av_push(seq, a);
                USE_OBJECT(a);
            }
            sv = newRV_noinc((SV*)seq);
#ifndef YAML_IS_JSON
            if (n->type_id) {
                char *lang = strtok(n->type_id, "/:");
                char *type = strtok(NULL, "");
                while ((type != NULL) && *type == '@') { type++; }

                if (lang == NULL || (strEQ(lang, "perl"))) {
                    sv_bless(sv, gv_stashpv(type, TRUE));
                } else {
                    sv_bless(sv, gv_stashpv(form("%s::%s", lang, type), TRUE));
                }
            }
#endif
        break;

        case syck_map_kind:
#ifndef YAML_IS_JSON
            if ( (n->type_id != NULL) && (strEQ( n->type_id, "perl/ref:" ) ) ) {
                SV* key = perl_syck_lookup_sym(p, syck_map_read(n, map_key, 0));
                SV* val = perl_syck_lookup_sym(p, syck_map_read(n, map_value, 0));
                char *ref_type = SvPVX(key);

                sv = newRV_noinc(val);
                USE_OBJECT(val);
                if (strnNE(ref_type, REF_LITERAL, REF_LITERAL_LENGTH+1)) {
                    sv_bless(sv, gv_stashpv(ref_type, TRUE));
                }
            }
            else
#endif
            {
                map = newHV();
                for (i = 0; i < n->data.pairs->idx; i++) {
                    SV* key = perl_syck_lookup_sym(p, syck_map_read(n, map_key, i));
                    SV* val = perl_syck_lookup_sym(p, syck_map_read(n, map_value, i));

                    if (hv_store_ent(map, key, val, 0) != NULL)
                       USE_OBJECT(val);
                }
                sv = newRV_noinc((SV*)map);
#ifndef YAML_IS_JSON
                if (n->type_id) {
                    char *lang = strtok(n->type_id, "/:");
                    char *type = strtok(NULL, "");
                    if (lang == NULL || strEQ(lang, "perl")) { /*  || (strchr(lang, '.') != NULL)) { */
                        sv_bless(sv, gv_stashpv(type, TRUE));
                    }
                    else if (type == NULL) {
                        sv_bless(sv, gv_stashpv(lang, TRUE));
                    }
                    else {
                        sv_bless(sv, gv_stashpv(form("%s::%s", lang, type), TRUE));
                    }
                }
#endif
            }
        break;
    }

#ifndef YAML_IS_JSON
    /* Fix bad anchors using sv_setsv */
    if (n->id) {
        sv_setsv( perl_syck_lookup_sym(p, n->id), sv );
    }
#endif

    TRACK_OBJECT(sv);

    return syck_add_sym(p, (char *)sv);
}

#ifdef YAML_IS_JSON
static char* perl_json_preprocess(char *s) {
    int i;
    char *out;
    char ch;
    bool in_string = 0;
    bool in_quote  = 0;
    char *pos;
    STRLEN len = strlen(s);

    New(2006, out, len*2+1, char);
    pos = out;

    for (i = 0; i < len; i++) {
        ch = *(s+i);
        *pos++ = ch;
        if (in_quote) {
            in_quote = !in_quote;
        }
        else if (ch == '\\') {
            in_quote = 1;
        }
        else if (ch == json_quote_char) {
            in_string = !in_string;
        }
        else if ((ch == ':' || ch == ',') && !in_string) {
            *pos++ = ' ';
        }
    }

    *pos = '\0';
    return out;
}

void perl_json_postprocess(SV *sv) {
    int i;
    char ch;
    bool in_string = 0;
    bool in_quote  = 0;
    char *pos;
    char *s = SvPVX(sv);
    STRLEN len = sv_len(sv);
    STRLEN final_len = len;

    pos = s;

    for (i = 0; i < len; i++) {
        ch = *(s+i);
        *pos++ = ch;
        if (in_quote) {
            in_quote = !in_quote;
        }
        else if (ch == '\\') {
            in_quote = 1;
        }
        else if (ch == json_quote_char) {
            in_string = !in_string;
        }
        else if ((ch == ':' || ch == ',') && !in_string) {
            i++; /* has to be a space afterwards */
            final_len--;
        }
    }

    /* Remove the trailing newline */
    if (final_len > 0) {
        final_len--; pos--;
    }
    *pos = '\0';
    SvCUR_set(sv, final_len);
}
#endif

static SV *
#ifdef YAML_IS_JSON
LoadJSON
#else
LoadYAML
#endif
(char *s) {
    SYMID v;
    SyckParser *parser;
    struct parser_xtra bonus;
    SV *obj = &PL_sv_undef;
    SV *implicit = GvSV(gv_fetchpv(form("%s::ImplicitTyping", PACKAGE_NAME), TRUE, SVt_PV));
    SV *use_code = GvSV(gv_fetchpv(form("%s::UseCode", PACKAGE_NAME), TRUE, SVt_PV));
    SV *load_code = GvSV(gv_fetchpv(form("%s::LoadCode", PACKAGE_NAME), TRUE, SVt_PV));
    SV *unicode = GvSV(gv_fetchpv(form("%s::ImplicitUnicode", PACKAGE_NAME), TRUE, SVt_PV));
#ifdef YAML_IS_JSON
    SV *singlequote = GvSV(gv_fetchpv(form("%s::SingleQuote", PACKAGE_NAME), TRUE, SVt_PV));
    json_quote_char = (SvTRUE(singlequote) ? '\'' : '"' );
    json_quote_style = (SvTRUE(singlequote) ? scalar_1quote : scalar_2quote );
#endif

    ENTER; SAVETMPS;

    /* Don't even bother if the string is empty. */
    if (*s == '\0') { return &PL_sv_undef; }

#ifdef YAML_IS_JSON
    s = perl_json_preprocess(s);
#else
    /* Special preprocessing to maintain compat with YAML.pm <= 0.35 */
    if (strnEQ( s, "--- #YAML:1.0", 13)) {
        s[4] = '%';
    }
#endif

    parser = syck_new_parser();
    syck_parser_str_auto(parser, s, NULL);
    syck_parser_handler(parser, PERL_SYCK_PARSER_HANDLER);
    syck_parser_error_handler(parser, perl_syck_error_handler);
    syck_parser_bad_anchor_handler( parser, perl_syck_bad_anchor_handler );
    syck_parser_implicit_typing(parser, SvTRUE(implicit));
    syck_parser_taguri_expansion(parser, 0);

    bonus.objects = (AV*)sv_2mortal((SV*)newAV());
    bonus.utf8 = SvTRUE(unicode);
	bonus.load_code = SvTRUE(use_code) || SvTRUE(load_code);
    parser->bonus = &bonus;

    v = syck_parse(parser);
    if (syck_lookup_sym(parser, v, (char **)&obj))
        USE_OBJECT(obj);
    syck_free_parser(parser);

#ifdef YAML_IS_JSON
    Safefree(s);
#endif

    FREETMPS; LEAVE;

    return obj;
}

void
#ifdef YAML_IS_JSON
json_syck_emitter_handler
#else
yaml_syck_emitter_handler
#endif
(SyckEmitter *e, st_data_t data) {
    I32  len, i;
    SV*  sv = (SV*)data;
    struct emitter_xtra *bonus = (struct emitter_xtra *)e->bonus;
    char* tag = bonus->tag;
	char dump_code = bonus->dump_code;
    char* ref = NULL;
    svtype ty = SvTYPE(sv);

#define OBJECT_TAG     "tag:perl:"
    
    if (SvMAGICAL(sv)) {
        mg_get(sv);
    }

#ifndef YAML_IS_JSON
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
#endif

    if (SvROK(sv)) {
#ifdef YAML_IS_JSON
        PERL_SYCK_EMITTER_HANDLER(e, (st_data_t)SvRV(sv));
#else
        switch (SvTYPE(SvRV(sv))) {
            case SVt_PVAV:
            case SVt_PVHV:
            case SVt_PVCV: {
                e->indent = 0;
                syck_emit_item(e, (st_data_t)SvRV(sv));
                e->indent = PERL_SYCK_INDENT_LEVEL;
                break;
            }
            default: {
                syck_emit_map(e, "tag:perl:ref:", MAP_NONE);
                syck_emit_item( e, (st_data_t)newSVpvn_share(REF_LITERAL, REF_LITERAL_LENGTH, 0) );
                syck_emit_item( e, (st_data_t)SvRV(sv) );
                syck_emit_end(e);
            }
        }
#endif
    }
    else if (ty == SVt_NULL) {
        syck_emit_scalar(e, "string", scalar_none, 0, 0, 0, NULL_LITERAL, NULL_LITERAL_LENGTH);
    }
    else if (SvNIOKp(sv) && (sv_len(sv) != 0)) {
        syck_emit_scalar(e, OBJOF("string"), SCALAR_NUMBER, 0, 0, 0, SvPV_nolen(sv), sv_len(sv));
    }
    else if (SvPOKp(sv)) {
        STRLEN len = sv_len(sv);
        if (len == 0) {
            syck_emit_scalar(e, OBJOF("string"), SCALAR_QUOTED, 0, 0, 0, "", 0);
        }
#ifndef YAML_IS_JSON
        else if ((len == NULL_LITERAL_LENGTH) && *(SvPV_nolen(sv)) == '~') {
            syck_emit_scalar(e, OBJOF("string"), SCALAR_QUOTED, 0, 0, 0, NULL_LITERAL, 1);
        }
#endif
        else if (COND_FOLD(sv)) {
            enum scalar_style old_s = e->style;
            e->style = SCALAR_UTF8;
            syck_emit_scalar(e, OBJOF("string"), SCALAR_STRING, 0, 0, 0, SvPV_nolen(sv), len);
            e->style = old_s;
        }
        else {
            syck_emit_scalar(e, OBJOF("string"), SCALAR_STRING, 0, 0, 0, SvPV_nolen(sv), len);
        }
    }
    else {
        switch (ty) {
            case SVt_PVAV: {
                syck_emit_seq(e, OBJOF("array"), SEQ_NONE);
                e->indent = PERL_SYCK_INDENT_LEVEL;

                *tag = '\0';
                len = av_len((AV*)sv) + 1;
                for (i = 0; i < len; i++) {
                    SV** sav = av_fetch((AV*)sv, i, 0);
                    if (sav == NULL) {
                        syck_emit_item( e, (st_data_t)(&PL_sv_undef) );
                    }
                    else {
                        syck_emit_item( e, (st_data_t)(*sav) );
                    }
                }
                syck_emit_end(e);
                return;
            }
            case SVt_PVHV: {
                HV *hv = (HV*)sv;
                syck_emit_map(e, OBJOF("hash"), MAP_NONE);
                e->indent = PERL_SYCK_INDENT_LEVEL;

                *tag = '\0';
#ifdef HAS_RESTRICTED_HASHES
                len = HvTOTALKEYS((HV*)sv);
#else
                len = HvKEYS((HV*)sv);
#endif
                hv_iterinit((HV*)sv);

                if (e->sort_keys) {
                    AV *av = (AV*)sv_2mortal((SV*)newAV());
                    for (i = 0; i < len; i++) {
#ifdef HAS_RESTRICTED_HASHES
                        HE *he = hv_iternext_flags(hv, HV_ITERNEXT_WANTPLACEHOLDERS);
#else
                        HE *he = hv_iternext(hv);
#endif
                        SV *key = hv_iterkeysv(he);
                        av_store(av, AvFILLp(av)+1, key);	/* av_push(), really */
                    }
                    STORE_HASH_SORT;
                    for (i = 0; i < len; i++) {
#ifdef HAS_RESTRICTED_HASHES
                        int placeholders = (int)HvPLACEHOLDERS_get(hv);
#endif
                        unsigned char flags = 0;
                        char *keyval;
                        STRLEN keylen_tmp;
                        I32 keylen;
                        SV *key = av_shift(av);
                        HE *he  = hv_fetch_ent(hv, key, 0, 0);
                        SV *val = HeVAL(he);
                        if (val == NULL) { val = &PL_sv_undef; }
                        syck_emit_item( e, (st_data_t)key );
                        syck_emit_item( e, (st_data_t)val );
                    }
                }
                else {
                    for (i = 0; i < len; i++) {
#ifdef HV_ITERNEXT_WANTPLACEHOLDERS
                        HE *he = hv_iternext_flags(hv, HV_ITERNEXT_WANTPLACEHOLDERS);
#else
                        HE *he = hv_iternext(hv);
#endif
                        I32 keylen;
                        SV *key = hv_iterkeysv(he);
                        SV *val = hv_iterval(hv, he);
                        syck_emit_item( e, (st_data_t)key );
                        syck_emit_item( e, (st_data_t)val );
                    }
                }
                syck_emit_end(e);
                return;
            }
            case SVt_PVCV: {
                /* XXX TODO XXX */
#ifdef YAML_IS_JSON
                syck_emit_scalar(e, "string", scalar_none, 0, 0, 0, NULL_LITERAL, NULL_LITERAL_LENGTH);
#else
	
				/* This following code is mostly copypasted from Storable */
				if ( !dump_code ) {
					syck_emit_scalar(e, "tag:perl:code:", SCALAR_QUOTED, 0, 0, 0, "{ \"DUMMY\" }", 11);
				} else {
					dSP;
					I32 len;
					int count, reallen;
					SV *text, *bdeparse;
					CV *cv = (CV*)sv;

					/*
					 * Require B::Deparse. At least B::Deparse 0.61 is needed for
					 * blessed code references.
					 */
					/* Ownership of both SVs is passed to load_module, which frees them. */
					load_module(PERL_LOADMOD_NOIMPORT, newSVpvn("B::Deparse",10), newSVnv(0.61));

					ENTER;
					SAVETMPS;

					/*
					 * create the B::Deparse object
					 */

					PUSHMARK(sp);
					XPUSHs(sv_2mortal(newSVpvn("B::Deparse",10)));
					PUTBACK;
					count = call_method("new", G_SCALAR);
					SPAGAIN;
					if (count != 1)
						CROAK(("Unexpected return value from B::Deparse::new\n"));
					bdeparse = POPs;

					/*
					 * call the coderef2text method
					 */

					PUSHMARK(sp);
					XPUSHs(bdeparse); /* XXX is this already mortal? */
					XPUSHs(sv_2mortal(newRV_inc((SV*)cv)));
					PUTBACK;
					count = call_method("coderef2text", G_SCALAR);
					SPAGAIN;
					if (count != 1)
						CROAK(("Unexpected return value from B::Deparse::coderef2text\n"));

					text = POPs;
					len = SvLEN(text);
					reallen = strlen(SvPV_nolen(text));

					/*
					 * Empty code references or XS functions are deparsed as
					 * "(prototype) ;" or ";".
					 */

					if (len == 0 || *(SvPV_nolen(text)+reallen-1) == ';') {
						CROAK(("The result of B::Deparse::coderef2text was empty - maybe you're trying to serialize an XS function?\n"));
					}

					/* 
					 * Signal code by emitting SX_CODE.
					 */

#if 0
					/* SYCK adds anchors for us automatically */

					PUTMARK(SX_CODE);
					cxt->tagnum++;   /* necessary, as SX_CODE is a SEEN() candidate */
#endif

					/*
					 * Now store the source code.
					 */

					syck_emit_scalar(e, "tag:perl:code:", SCALAR_UTF8, 0, 0, 0, SvPV_nolen(text), len-1);

					FREETMPS;
					LEAVE;

					/* END Storable */
				}
#endif
                break;
            }
            case SVt_PVGV:
            case SVt_PVFM: {
                /* XXX TODO XXX */
                syck_emit_scalar(e, OBJOF("string"), SCALAR_STRING, 0, 0, 0, SvPV_nolen(sv), sv_len(sv));
                break;
            }
            case SVt_PVIO: {
                syck_emit_scalar(e, OBJOF("string"), SCALAR_STRING, 0, 0, 0, SvPV_nolen(sv), sv_len(sv));
                break;
            }
            default: {
                syck_emit_scalar(e, "string", scalar_none, 0, 0, 0, NULL_LITERAL, NULL_LITERAL_LENGTH);
            }
        }
    }
cleanup:
    *tag = '\0';
}

SV*
#ifdef YAML_IS_JSON
DumpJSON
#else
DumpYAML
#endif
(SV *sv) {
    struct emitter_xtra bonus;
    SV* out = newSVpvn("", 0);
    SyckEmitter *emitter = syck_new_emitter();
    SV *headless = GvSV(gv_fetchpv(form("%s::Headless", PACKAGE_NAME), TRUE, SVt_PV));
    SV *unicode = GvSV(gv_fetchpv(form("%s::ImplicitUnicode", PACKAGE_NAME), TRUE, SVt_PV));
    SV *use_code = GvSV(gv_fetchpv(form("%s::UseCode", PACKAGE_NAME), TRUE, SVt_PV));
    SV *dump_code = GvSV(gv_fetchpv(form("%s::DumpCode", PACKAGE_NAME), TRUE, SVt_PV));
    SV *sortkeys = GvSV(gv_fetchpv(form("%s::SortKeys", PACKAGE_NAME), TRUE, SVt_PV));
#ifdef YAML_IS_JSON
    SV *singlequote = GvSV(gv_fetchpv(form("%s::SingleQuote", PACKAGE_NAME), TRUE, SVt_PV));
    json_quote_char = (SvTRUE(singlequote) ? '\'' : '"' );
    json_quote_style = (SvTRUE(singlequote) ? scalar_1quote : scalar_2quote );
    emitter->indent = PERL_SYCK_INDENT_LEVEL;
#endif

    ENTER; SAVETMPS;

    emitter->headless = SvTRUE(headless);
    emitter->sort_keys = SvTRUE(sortkeys);
    emitter->anchor_format = "%d";

    bonus.port = out;
    New(801, bonus.tag, 512, char);
	bonus.dump_code = SvTRUE(use_code) || SvTRUE(dump_code);
    emitter->bonus = &bonus;

    syck_emitter_handler( emitter, PERL_SYCK_EMITTER_HANDLER );
    syck_output_handler( emitter, perl_syck_output_handler );

#ifndef YAML_IS_JSON
    perl_syck_mark_emitter( emitter, sv );
#endif

    syck_emit( emitter, (st_data_t)sv );
    syck_emitter_flush( emitter, 0 );
    syck_free_emitter( emitter );

    Safefree(bonus.tag);

#ifdef YAML_IS_JSON
    if (SvCUR(out) > 0) {
        perl_json_postprocess(out);
    }
#endif

    if (SvTRUE(unicode)) {
        SvUTF8_on(out);
    }

    FREETMPS; LEAVE;

    return out;
}

