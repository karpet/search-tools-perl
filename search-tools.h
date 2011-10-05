/* Copyright 2009 Peter Karman
 *
 * This program is free software; you can redistribute it and/or modify
 * under the same terms as Perl itself.
 */

/*
 * Search::Tools C helpers
 */

#define ST_CROAK(args, ...) st_croak(__FILE__, __LINE__, FUNCTION__, args)

#define ST_CLASS_TOKEN      "Search::Tools::Token"
#define ST_CLASS_TOKENLIST  "Search::Tools::TokenList"
#define ST_BAD_UTF8 "str must be UTF-8 encoded and flagged by Perl. \
See the Search::Tools::to_utf8() function."


typedef char    boolean;
typedef struct  st_token st_token;
typedef struct  st_token_list st_token_list;
struct st_token {
    I32             pos;        /* position in buffer */
    I32             len;        /* token length (bytes) */
    I32             u8len;      /* token length (utf8 chars) */
    SV             *str;        /* SV* for the string */
    I32             is_hot;     /* interesting token flag */
    boolean         is_sentence_start;  /* looks like the start of a sentence */
    boolean         is_sentence_end;    /* looks like the end of a sentence */
    boolean         is_match;   /* matched regex */
    IV              ref_cnt;    /* reference counter */
};
struct st_token_list {
    I32             pos;        /* current iterator position (array index) */
    I32             num;        /* number of parsed tokens */
    AV             *tokens;     /* array of st_token objects */
    AV             *heat;       /* array of positions of is_hot tokens */
    AV             *sentence_starts;  /* array of sentence start positions */
    IV              ref_cnt;    /* reference counter */
};

static st_token*    
st_new_token(
    I32 pos, 
    I32 len,
    I32 u8len,
    const char *ptr,
    I32 is_hot,
    boolean is_match
);

static st_token_list* st_new_token_list(
    AV *tokens,
    AV *heat,
    AV *sentence_starts,
    unsigned int num
);
static void     st_dump_token_list(st_token_list *tl);
static void     st_dump_token(st_token *tok);
/* UNUSED
static SV*      st_hv_store( HV* h, const char* key, SV* val );
static SV*      st_hv_store_char( HV* h, const char* key, char *val );
static SV*      st_hv_store_int( HV* h, const char* key, int i);
static SV*      st_hvref_store_int( SV* h, const char* key, int i);
static SV*      st_hvref_store( SV* h, const char* key, SV* val );
static SV*      st_hvref_store_char( SV* h, const char* key, char *val );
*/
static SV*      st_av_fetch( AV* a, I32 index );
static void*    st_av_fetch_ptr( AV* a, I32 index );
static SV*      st_hv_fetch( HV* h, const char* key );
static SV*      st_hvref_fetch( SV* h, const char* key );
/* UNUSED
static char*    st_hv_fetch_as_char( HV* h, const char* key );
static char*    st_hvref_fetch_as_char( SV* h, const char* key );
static IV       st_hvref_fetch_as_int( SV* h, const char* key );
*/
static SV*      st_tokenize( 
    SV* str, 
    SV* token_re, 
    SV* heat_seeker, 
    I32 match_num 
);
static void     st_heat_seeker( st_token *token, SV *re );
static AV*      st_heat_seeker_offsets( SV *str, SV *re );
static REGEXP*  st_get_regex_from_sv( SV* regex_sv );
/* UNUSED
static SV*      st_new_hash_object(const char *class);
*/
static SV*      st_bless_ptr( const char* class, void * c_ptr );
static void*    st_extract_ptr( SV* object );
static void*    st_malloc(size_t size);
static void     st_free_token(st_token *tok);
static void     st_croak(
    const char *file,
    int line,
    const char *func,
    const char *msgfmt,
    ...
);
static void     st_dump_sv( SV* hash_ref );
static void     st_describe_object( SV* object );
static boolean  st_is_ascii( SV* str );
static boolean  st_char_is_ascii( unsigned char* str, STRLEN len );
static SV*      st_find_bad_utf8( SV* str );
static SV*      st_escape_xml(char *s);
static IV       st_looks_like_sentence_start(const unsigned char *ptr, IV len);
static IV       st_looks_like_sentence_end(const unsigned char *ptr, IV len);
static IV       st_utf8_codepoint(const unsigned char *utf8, IV len);
