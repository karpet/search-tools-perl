/* Copyright 2009 Peter Karman
 *
 * This program is free software; you can redistribute it and/or modify
 * under the same terms as Perl itself.
 */

/*
 * Search::Tools C helpers
 */

#include "search-tools.h"

/* store SV* in a hash, incrementing its refcnt */
static SV*
st_hv_store( HV* h, const char* key, SV* val) {
    dTHX;
    SV** ok;
    ok = hv_store(h, key, strlen(key), SvREFCNT_inc(val), 0);
    if (ok == NULL) {
        ST_CROAK("failed to store %s in hash", key);
    }
    return *ok;
}

static SV*
st_hv_store_char( HV* h, const char *key, char *val) {
    dTHX;
    SV *value;
    value = newSVpv(val, 0);
    st_hv_store( h, key, value );
    SvREFCNT_dec(value);
    return value;
}

static SV*      
st_hv_store_int( HV* h, const char* key, int i) {
    dTHX;
    SV *value;
    value = newSViv(i);
    st_hv_store( h, key, value );
    SvREFCNT_dec(value);
    return value;
}

static SV*
st_hvref_store( SV* h, const char* key, SV* val) {
    dTHX;
    return st_hv_store( (HV*)SvRV(h), key, val );
}

static SV*
st_hvref_store_char( SV* h, const char* key, char *val) {
    dTHX;
    return st_hv_store_char( (HV*)SvRV(h), key, val );
}

static SV*
st_hvref_store_int( SV* h, const char* key, int i) {
    dTHX;
    return st_hv_store_int( (HV*)SvRV(h), key, i );
}

static SV*
st_av_fetch( AV* a, I32 index ) {
    dTHX;
    SV** ok;
    ok = av_fetch(a, index, 0);
    if (ok == NULL) {
        ST_CROAK("failed to fetch index %d", index);
    }
    return *ok;
}

/* fetch SV* from hash */
static SV*
st_hv_fetch( HV* h, const char* key ) {
    dTHX; /* thread-safe perlism */
    SV** ok;
    ok = hv_fetch(h, key, strlen(key), 0);
    if (ok == NULL) {
        ST_CROAK("failed to fetch %s", key);
    }
    return *ok;
}

static SV*
st_hvref_fetch( SV* h, const char* key ) {
    dTHX; /* thread-safe perlism */
    return st_hv_fetch((HV*)SvRV(h), key);
}

/* fetch SV* from hash */
static char*
st_hv_fetch_as_char( HV* h, const char* key ) {
    dTHX;
    SV** ok;
    ok = hv_fetch(h, key, strlen(key), 0);
    if (ok == NULL) {
        ST_CROAK("failed to fetch %s from hash", key);
    }
    return SvPV((SV*)*ok, PL_na);
}

static char*
st_hvref_fetch_as_char( SV* h, const char* key ) {
    dTHX;
    return st_hv_fetch_as_char( (HV*)SvRV(h), key );
}

static IV
st_hvref_fetch_as_int( SV* h, const char* key ) {
    dTHX;
    SV* val;
    IV i;
    val = st_hv_fetch( (HV*)SvRV(h), key );
    i = SvIV(val);
    return i;
}

void *
st_malloc(size_t size) {
    void *ptr;
    ptr = malloc(size);
    if (ptr == NULL) {
        ST_CROAK("Out of memory! Can't malloc %lu bytes",
                    (unsigned long)size);
    }
    return ptr;
}


static st_token*    
st_new_token(
    unsigned int pos, 
    unsigned int len,
    const char *offset,
    boolean is_hot,
    boolean is_match
) {
    dTHX;
    st_token *tok;
    tok = st_malloc(sizeof(st_token));
    tok->pos = pos;
    tok->len = len;
    tok->offset = offset;
    tok->is_hot = is_hot;
    tok->is_match = is_match;
    return tok;
}

static void
st_free_token(st_token *tok) {
    dTHX;
    free(tok);
}

/* make a Perl blessed object from a C pointer */
static SV* 
st_bless_ptr( const char *class, IV c_ptr ) {
    dTHX;
    SV* obj = sv_newmortal();
    sv_setref_pv(obj, class, (void*)c_ptr);
    return obj;
}

/* return the C pointer from a Perl blessed O_OBJECT */
static IV 
st_extract_ptr( SV* object ) {
    dTHX;
    return SvIV((SV*)SvRV( object ));
}

static void
st_croak(
    const char *file,
    int line,
    const char *func,
    const char *msgfmt,
    ...
)
{
    va_list args;
    va_start(args, msgfmt);
    warn("Search::Tools error at %s:%d %s: ", file, line, func);
    croak(msgfmt, args);
    va_end(args);
}

static SV*
st_new_hash_object(const char *class) {
    dTHX; /* thread-safe perlism */
    HV *hash;
    SV *object;
    hash    = newHV();
    object  = sv_bless( newRV((SV*)hash), gv_stashpv(class,0) );
    return object;
}

static void 
st_dump_hash(SV* ref) {
    dTHX;
    HV* hash;
    HE* hash_entry;
    int num_keys, i;
    SV* sv_key;
    SV* sv_val;
    int refcnt;
    
    if (SvTYPE(SvRV(ref))==SVt_PVHV) {
        warn("SV is a hash reference");
        hash        = (HV*)SvRV(ref);
        num_keys    = hv_iterinit(hash);
        for (i = 0; i < num_keys; i++) {
            hash_entry  = hv_iternext(hash);
            sv_key      = hv_iterkeysv(hash_entry);
            sv_val      = hv_iterval(hash, hash_entry);
            refcnt      = SvREFCNT(sv_val);
            warn("  %s => %s  [%d]\n", SvPV(sv_key, PL_na), SvPV(sv_val, PL_na), refcnt);
        }
    }
    else if (SvTYPE(SvRV(ref))==SVt_PVAV) {
        warn("SV is an array reference");
        warn("SV has %d items\n", av_len((AV*)SvRV(ref)));
        
    }

    return;
}

static void 
st_describe_object( SV* object ) {
    dTHX;
    char* str;
    
    warn("describing object\n");
    str = SvPV( object, PL_na );
    if (SvROK(object))
    {
      if (SvTYPE(SvRV(object))==SVt_PVHV)
        warn("%s is a magic blessed reference\n", str);
      else if (SvTYPE(SvRV(object))==SVt_PVMG)
        warn("%s is a magic reference", str);
      else if (SvTYPE(SvRV(object))==SVt_IV)
        warn("%s is a IV reference (pointer)", str); 
      else
        warn("%s is a reference of some kind", str);
    }
    else
    {
        warn("%s is not a reference", str);
        if (sv_isobject(object))
            warn("however, %s is an object", str);
        
        
    }
    warn("object dump");
    Perl_sv_dump( aTHX_ object );
    warn("object ref dump");
    Perl_sv_dump( aTHX_ (SV*)SvRV(object) );
    st_dump_hash( object );
}


/*
    st_tokenize() et al based on KinoSearch::Analysis::Tokenizer 
    by Marvin Humphrey.
    He dared go where no XS regex user had gone before...
*/

static SV*
st_tokenize( SV* str, SV* token_re ) {
    dTHX; /* thread-safe perlism */
    
/* declare */
    unsigned int     num_tokens;
    MAGIC           *mg;
    REGEXP          *rx;
    SV              *wrapper;
    char            *str_start;
    int              str_len;
    char            *str_end;
    char            *buf;
    int              offset;
    const char      *prev_end, *prev_start;
    AV              *tokens;
    SV              *token_list;
    SV              *tok;

/* initialize */
    token_list      = st_new_hash_object("Search::Tools::TokenList");
    num_tokens      = 0;
    mg              = NULL;
    rx              = NULL;
    wrapper         = sv_newmortal();
    /* copy the original string, then get the new char* ptr 
     * and ref it from each token 
     */
    st_hvref_store_char(token_list, "buf", SvPV(str, PL_na)); 
    buf             = st_hvref_fetch_as_char(token_list, "buf");
    str_start       = buf;
    str_len         = strlen(buf);
    str_end         = str_start + str_len;
    prev_start      = str_start;
    prev_end        = prev_start;
    offset          = 0;
    tokens          = newAV();
        
/* extract regexp struct from qr// entity */
    if (SvROK(token_re)) {
        SV *sv = SvRV(token_re);
        if (SvMAGICAL(sv))
            mg = mg_find(sv, PERL_MAGIC_qr);
    }
    if (!mg)
        ST_CROAK("regex is not a qr// entity");
        
    rx = (REGEXP*)mg->mg_obj;
    
/* fake up an SV wrapper to feed to the regex engine */
    sv_upgrade(wrapper, SVt_PV);
    SvREADONLY_on(wrapper);
    SvLEN(wrapper) = 0;
    SvUTF8_on(wrapper);     /* do UTF8 matching */
    
/* wrap the string in an SV to please the regex engine */
/* TODO could we just use str ? */
    SvPVX(wrapper) = str_start;
    SvCUR_set(wrapper, str_len);
    SvPOK_on(wrapper);
    
    //warn("tokenizing: '%s'\n", buf);
    
    while ( pregexec(rx, buf, str_end, buf, 1, wrapper, 1) ) 
    {
        unsigned int token_len;
        const char *start_ptr, *end_ptr;
        st_token *token;
        
#if ((PERL_VERSION > 9) || (PERL_VERSION == 9 && PERL_SUBVERSION >= 5))
        start_ptr = buf + rx->offs[0].start;
        end_ptr   = buf + rx->offs[0].end;
#else
        start_ptr = buf + rx->startp[0];
        end_ptr   = buf + rx->endp[0];
#endif

        /* advance the pointers */
        buf = (char*)end_ptr;
        
        /* create token for the bytes between the last match and this one */
        /* check first that we have moved past first byte */
        if (start_ptr != str_start) {
            token = st_new_token(num_tokens++, (start_ptr - prev_end),
                                 prev_end, 0, 0);
            //warn("prev: [%d] [%d] [%s]", token->pos, token->len, token->offset);
            tok = st_bless_ptr("Search::Tools::Token", (IV)token);
            //st_describe_object( tok );
            av_push(tokens, SvREFCNT_inc(tok));
        }
        
        /* create token object for the current match */            
        token = st_new_token(num_tokens++, 
                            (end_ptr - start_ptr), 
                            start_ptr,
                            0, 1);
                            
        //warn("[%d] [%d] [%s]", token->pos, token->len, token->offset);

        tok = st_bless_ptr("Search::Tools::Token", (IV)token);
        //st_describe_object( tok );
        av_push(tokens, SvREFCNT_inc(tok));
        
        /* remember where we are for next time */
        prev_end = end_ptr;
        prev_start = start_ptr;
    }
    
    if (prev_end != str_end) {
        /* some bytes after the last match */
        st_token *token = st_new_token(num_tokens++, 
                                    (str_end - prev_end),
                                    prev_end, 
                                    0, 0);
        tok = st_bless_ptr("Search::Tools::Token", (IV)token);
        //st_describe_object( tok );
        av_push(tokens, SvREFCNT_inc(tok));
    }
    
    /* flesh out the object */
    st_hvref_store(token_list, "list", newRV((SV*)tokens));
    st_hvref_store_int(token_list, "num", num_tokens-1); /* -1 because we already increm */
    st_hvref_store_int(token_list, "pos", 0);
    
    return token_list;
}

