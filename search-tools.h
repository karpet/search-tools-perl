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

typedef char    boolean;
typedef struct  st_token st_token;
struct st_token {
    unsigned int    pos;    // this token's position in document
    unsigned int    len;
    const char      *offset;
    boolean         is_hot;
    boolean         is_match;    
};

static st_token*    
st_new_token(
    unsigned int pos, 
    unsigned int len,
    const char *offset,
    boolean is_hot,
    boolean is_match
);

static SV*      st_hv_store( HV* h, const char* key, SV* val );
static SV*      st_hv_store_char( HV* h, const char* key, char *val );
static SV*      st_hv_store_int( HV* h, const char* key, int i);
static SV*      st_hvref_store_int( SV* h, const char* key, int i);
static SV*      st_hvref_store( SV* h, const char* key, SV* val );
static SV*      st_hvref_store_char( SV* h, const char* key, char *val );
static SV*      st_av_fetch( AV* a, I32 index );
static SV*      st_hv_fetch( HV* h, const char* key );
static SV*      st_hvref_fetch( SV* h, const char* key );
static char*    st_hv_fetch_as_char( HV* h, const char* key );
static char*    st_hvref_fetch_as_char( SV* h, const char* key );
static IV       st_hvref_fetch_as_int( SV* h, const char* key );
static SV*      st_tokenize( SV* str, SV* token_re );
static SV*      st_new_hash_object(const char *class);
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
static void     st_dump_hash( SV* hash_ref );
static void     st_describe_object( SV* object );
