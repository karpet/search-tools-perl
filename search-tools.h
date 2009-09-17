/* Copyright 2009 Peter Karman
 *
 * This program is free software; you can redistribute it and/or modify
 * under the same terms as Perl itself.
 */

/*
 * Search::Tools C helpers
 */
 
#define ST_CROAK(args...) \
    st_croak(__FILE__, __LINE__, __func__, args)

#define ST_CLASS_TOKEN      "Search::Tools::Token"
#define ST_CLASS_TOKENLIST  "Search::Tools::TokenList"
#define ST_BAD_UTF8 "str must be UTF-8 encoded and flagged by Perl. \
See the Search::Tools::to_utf8() function."


typedef char    boolean;
typedef struct  st_token st_token;
typedef struct  st_token_list st_token_list;
struct st_token {
    IV              pos;        // position in buffer
    IV              len;        // token length (bytes)
    IV              u8len;      // token length (utf8 chars)
    SV             *str;        // SV* for the string
    IV              is_hot;     // interesting token flag
    boolean         is_match;   // matched regex
    IV              ref_cnt;    // reference counter
};
struct st_token_list {
    IV              pos;        // current iterator position (array index)
    IV              num;        // number of parsed tokens
    AV             *tokens;     // array of st_token objects
    AV             *heat;       // array of positions of is_hot tokens
    IV              ref_cnt;    // reference counter
};

static st_token*    
st_new_token(
    IV pos, 
    IV len,
    IV u8len,
    const char *ptr,
    IV is_hot,
    boolean is_match
);

static st_token_list* st_new_token_list(
    AV *tokens,
    AV *heat,
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
    IV match_num 
);
static void     st_heat_seeker( st_token *token, SV *re );
static REGEXP*  st_get_regex_from_sv( SV* regex_sv );
/* UNUSED
static SV*      st_new_hash_object(const char *class);
*/
static SV*      st_bless_ptr( const char* class, IV c_ptr );
static IV       st_extract_ptr( SV* object );
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
static SV*      st_find_bad_utf8( SV* str );
