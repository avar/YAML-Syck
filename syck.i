#pragma SWIG nowarn=302,451,509

%{
#include "syck.h"
typedef SV* Perl_Scalar;
%}

%typemap(in) st_data_t {
    $1 = (st_data_t)($input);
}

%typemap(out) st_data_t {
    $result = newSVsv((SV *)$1);
    sv_2mortal($result);
    argvi++;
}

%typemap(in) Perl_Scalar {
    $1 = (void *)$input;
}

%typemap(out) Perl_Scalar {
    $result = newSVsv((SV *)$1);
    sv_2mortal($result);
    argvi++;
}

void  syck_perl_set_parser_handler(SyckParser *);
SYMID syck_perl_parser_handler(SyckParser *, SyckNode *);

void  syck_perl_set_emitter_handler(SyckEmitter *, Perl_Scalar);
void  syck_perl_set_output_handler(SyckEmitter *, Perl_Scalar);
void  syck_perl_mark_emitter(SyckEmitter *);

Perl_Scalar syck_perl_lookup_sym( SyckParser *, SYMID);

#####################################################

typedef struct _syck_node SyckNode;

enum syck_kind_tag {
    syck_map_kind,
    syck_seq_kind,
    syck_str_kind
};

enum map_part {
    map_key,
    map_value
};

enum map_style {
    map_none,
    map_inline
};

enum seq_style {
    seq_none,
    seq_inline
};

enum scalar_style {
    scalar_none,
    scalar_1quote,
    scalar_2quote,
    scalar_fold,
    scalar_literal,
    scalar_plain
};

/*
 * Node metadata struct
 */
struct _syck_node {
    /* Symbol table ID */
    SYMID id;
    /* Underlying kind */
    enum syck_kind_tag kind;
    /* Fully qualified tag-uri for type */
    char *type_id;
    /* Anchor name */
    char *anchor;
    union {
        /* Storage for map data */
        struct SyckMap {
            enum map_style style;
            SYMID *keys;
            SYMID *values;
            long capa;
            long idx;
        } *pairs;
        /* Storage for sequence data */
        struct SyckSeq {
            enum seq_style style;
            SYMID *items;
            long capa;
            long idx;
        } *list;
        /* Storage for string data */
        struct SyckStr {
            enum scalar_style style;
            char *ptr;
            long len;
        } *str;
    } data;
    /* Shortcut node */
    void *shortcut;
};

/*
 * Parser definitions
 */
typedef struct _syck_parser SyckParser;
typedef struct _syck_file SyckIoFile;
typedef struct _syck_str SyckIoStr;
typedef struct _syck_level SyckLevel;

typedef SYMID (*SyckNodeHandler)(SyckParser *, SyckNode *);
typedef void (*SyckErrorHandler)(SyckParser *, char *);
typedef SyckNode * (*SyckBadAnchorHandler)(SyckParser *, char *);
typedef long (*SyckIoFileRead)(char *, SyckIoFile *, long, long); 
typedef long (*SyckIoStrRead)(char *, SyckIoStr *, long, long);

enum syck_io_type {
    syck_io_str,
    syck_io_file
};

enum syck_parser_input {
    syck_yaml_utf8,
    syck_yaml_utf16,
    syck_yaml_utf32,
    syck_bytecode_utf8
};

enum syck_level_status {
    syck_lvl_header,
    syck_lvl_doc,
    syck_lvl_open,
    syck_lvl_seq,
    syck_lvl_map,
    syck_lvl_block,
    syck_lvl_str,
    syck_lvl_iseq,
    syck_lvl_imap,
    syck_lvl_end,
    syck_lvl_pause,
    syck_lvl_anctag,
    syck_lvl_mapx,
    syck_lvl_seqx
};

/*
 * Parser structs
 */
struct _syck_file {
    /* File pointer */
    FILE *ptr;
    /* Function which FILE -> buffer */
    SyckIoFileRead read;
};

struct _syck_str {
    /* String buffer pointers */
    char *beg, *ptr, *end;
    /* Function which string -> buffer */
    SyckIoStrRead read;
};

struct _syck_level {
    /* Indent */
    int spaces;
    /* Counts nodes emitted at this level, useful for parsing 
     * keys and pairs in bytecode */
    int ncount;
    /* Does node have anchors or tags? */
    int anctag;
    /* Domain prefixing at the given level */
    char *domain;
    /* Keeps a node status */
    enum syck_level_status status;
};

struct _syck_parser {
    /* Root node */
    SYMID root, root_on_error;
    /* Implicit typing flag */
    int implicit_typing, taguri_expansion;
    /* Scripting language function to handle nodes */
    SyckNodeHandler handler;
    /* Error handler */
    SyckErrorHandler error_handler;
    /* InvalidAnchor handler */
    SyckBadAnchorHandler bad_anchor_handler;
    /* Parser input type */
    enum syck_parser_input input_type;
    /* IO type */
    enum syck_io_type io_type;
    /* Custom buffer size */
    size_t bufsize;
    /* Buffer pointers */
    char *buffer, *linectptr, *lineptr, *toktmp, *token, *cursor, *marker, *limit;
    /* Line counter */
    int linect;
    /* Last token from yylex() */
    int last_token;
    /* Force a token upon next call to yylex() */
    int force_token;
    /* EOF flag */
    int eof;
    union {
        SyckIoFile *file;
        SyckIoStr *str;
    } io;
    /* Symbol table for anchors */
    st_table *anchors, *bad_anchors;
    /* Optional symbol table for SYMIDs */
    st_table *syms;
    /* Levels of indentation */
    SyckLevel *levels;
    int lvl_idx;
    int lvl_capa;
    /* Pointer for extension's use */
    void *bonus;
};

/*
 * Emitter definitions
 */
typedef struct _syck_emitter SyckEmitter;
typedef struct _syck_emitter_node SyckEmitterNode;

typedef void (*SyckOutputHandler)(SyckEmitter *, char *, long); 
typedef void (*SyckEmitterHandler)(SyckEmitter *, st_data_t); 

enum doc_stage {
    doc_open,
    doc_processing
};

/*
 * Emitter struct
 */
struct _syck_emitter {
    /* Headerless doc flag */
    int headless;
    /* Force header? */
    int use_header;
    /* Force version? */
    int use_version;
    /* Sort hash keys */
    int sort_keys;
    /* Anchor format */
    char *anchor_format;
    /* Explicit typing on all collections? */
    int explicit_typing;
    /* Best width on folded scalars */
    int best_width;
    /* Use literal[1] or folded[2] blocks on all text? */
    enum scalar_style style;
    /* Stage of written document */
    enum doc_stage stage;
    /* Level counter */
    int level;
    /* Default indentation */
    int indent;
    /* Object ignore ID */
    SYMID ignore_id;
    /* Symbol table for anchors */
    st_table *markers, *anchors, *anchored;
    /* Custom buffer size */
    size_t bufsize;
    /* Buffer */
    char *buffer, *marker;
    /* Absolute position of the buffer */
    long bufpos;
    /* Handler for emitter nodes */
    SyckEmitterHandler emitter_handler;
    /* Handler for output */
    SyckOutputHandler output_handler;
    /* Levels of indentation */
    SyckLevel *levels;
    int lvl_idx;
    int lvl_capa;
    /* Pointer for extension's use */
    void *bonus;
};

/*
 * Emitter node metadata struct
 */
struct _syck_emitter_node {
    /* Node buffer position */
    long pos;
    /* Current indent */
    long indent;
    /* Collection? */
    int is_shortcut;
};

/*
 * Handler prototypes
 */
SYMID syck_hdlr_add_node( SyckParser *, SyckNode * );
SyckNode *syck_hdlr_add_anchor( SyckParser *, char *, SyckNode * );
void syck_hdlr_remove_anchor( SyckParser *, char * );
SyckNode *syck_hdlr_get_anchor( SyckParser *, char * );
void syck_add_transfer( char *, SyckNode *, int );
char *syck_xprivate( char *, int );
char *syck_taguri( char *, char *, int );
int syck_tagcmp( char *, char * );
int syck_add_sym( SyckParser *, char * );
int syck_lookup_sym( SyckParser *, SYMID, char ** );
int syck_try_implicit( SyckNode * );
char *syck_type_id_to_uri( char * );
void try_tag_implicit( SyckNode *, int );
char *syck_match_implicit( char *, size_t );

/*
 * API prototypes
 */
char *syck_strndup( char *, long );
long syck_io_file_read( char *, SyckIoFile *, long, long );
long syck_io_str_read( char *, SyckIoStr *, long, long );
char *syck_base64enc( char *, long );
char *syck_base64dec( char *, long );
SyckEmitter *syck_new_emitter();
SYMID syck_emitter_mark_node( SyckEmitter *, st_data_t );
void syck_output_handler( SyckEmitter *, SyckOutputHandler );
void syck_emitter_handler( SyckEmitter *, SyckEmitterHandler );
void syck_free_emitter( SyckEmitter * );
void syck_emitter_clear( SyckEmitter * );
void syck_emitter_write( SyckEmitter *, char *, long );
void syck_emitter_escape( SyckEmitter *, char *, long );
void syck_emitter_flush( SyckEmitter *, long );
void syck_emit( SyckEmitter *, st_data_t );
void syck_emit_scalar( SyckEmitter *, char *, enum scalar_style, int, int, char, char *, long );
void syck_emit_1quoted( SyckEmitter *, int, char *, long );
void syck_emit_2quoted( SyckEmitter *, int, char *, long );
void syck_emit_folded( SyckEmitter *, int, char, char *, long );
void syck_emit_literal( SyckEmitter *, char, char *, long );
void syck_emit_seq( SyckEmitter *, char *, enum seq_style );
void syck_emit_item( SyckEmitter *, st_data_t );
void syck_emit_map( SyckEmitter *, char *, enum map_style );
void syck_emit_end( SyckEmitter * );
void syck_emit_tag( SyckEmitter *, char *, char * );
void syck_emit_indent( SyckEmitter * );
SyckLevel *syck_emitter_current_level( SyckEmitter * );
SyckLevel *syck_emitter_parent_level( SyckEmitter * );
void syck_emitter_pop_level( SyckEmitter * );
void syck_emitter_add_level( SyckEmitter *, int, enum syck_level_status );
void syck_emitter_reset_levels( SyckEmitter * );
SyckParser *syck_new_parser();
void syck_free_parser( SyckParser * );
void syck_parser_set_root_on_error( SyckParser *, SYMID );
void syck_parser_implicit_typing( SyckParser *, int );
void syck_parser_taguri_expansion( SyckParser *, int );
int syck_scan_scalar( int, char *, long );
void syck_parser_handler( SyckParser *, SyckNodeHandler );
void syck_parser_error_handler( SyckParser *, SyckErrorHandler );
void syck_parser_bad_anchor_handler( SyckParser *, SyckBadAnchorHandler );
void syck_parser_file( SyckParser *, FILE *, SyckIoFileRead );
void syck_parser_str( SyckParser *, char *, long, SyckIoStrRead );
void syck_parser_str_auto( SyckParser *, char *, SyckIoStrRead );
SyckLevel *syck_parser_current_level( SyckParser * );
void syck_parser_add_level( SyckParser *, int, enum syck_level_status );
void syck_parser_pop_level( SyckParser * );
void free_any_io( SyckParser * );
long syck_parser_read( SyckParser * );
long syck_parser_readlen( SyckParser *, long );
SYMID syck_parse( SyckParser * );
void syck_default_error_handler( SyckParser *, char * );
SYMID syck_yaml2byte_handler( SyckParser *, SyckNode * );
char *syck_yaml2byte( char * );

/*
 * Allocation prototypes
 */
SyckNode *syck_alloc_map();
SyckNode *syck_alloc_seq();
SyckNode *syck_alloc_str();
void syck_free_node( SyckNode * );
void syck_free_members( SyckNode * );
SyckNode *syck_new_str( char *, enum scalar_style );
SyckNode *syck_new_str2( char *, long, enum scalar_style );
void syck_replace_str( SyckNode *, char *, enum scalar_style );
void syck_replace_str2( SyckNode *, char *, long, enum scalar_style );
void syck_str_blow_away_commas( SyckNode * );
char *syck_str_read( SyckNode * );
SyckNode *syck_new_map( SYMID, SYMID );
void syck_map_empty( SyckNode * );
void syck_map_add( SyckNode *, SYMID, SYMID );
SYMID syck_map_read( SyckNode *, enum map_part, long );
void syck_map_assign( SyckNode *, enum map_part, long, SYMID );
long syck_map_count( SyckNode * );
void syck_map_update( SyckNode *, SyckNode * );
SyckNode *syck_new_seq( SYMID );
void syck_seq_empty( SyckNode * );
void syck_seq_add( SyckNode *, SYMID );
void syck_seq_assign( SyckNode *, long, SYMID );
SYMID syck_seq_read( SyckNode *, long );
long syck_seq_count( SyckNode * );

/*
 * Lexer prototypes
 */
void syckerror( char * );
int syckparse( void * );
