/* Copyright 2009 Peter Karman
 *
 * This program is free software; you can redistribute it and/or modify
 * under the same terms as Perl itself.
 */

/*
 * Search::Tools C helpers
 */

#include "search-tools.h"

/* global debug var */
static boolean ST_DEBUG;

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
    IV pos, 
    IV len,
    IV u8len,
    const char *ptr,
    boolean is_hot,
    boolean is_match
) {
    dTHX;
    st_token *tok;
    tok = st_malloc(sizeof(st_token));
    tok->pos = pos;
    tok->len = len;
    tok->u8len = u8len;
    tok->is_hot = is_hot;
    tok->is_match = is_match;
    tok->str = newSVpvn_utf8(ptr, len, 1);
    tok->ref_cnt = 1;
    return tok;
}

static st_token_list*
st_new_token_list(
    AV *tokens, 
    unsigned int num
) {
    dTHX;
    st_token_list *tl;
    tl = st_malloc(sizeof(st_token_list));
    tl->pos = 0;
    tl->tokens = tokens;
    tl->num = (IV)num;
    tl->ref_cnt = 1;
    return tl;
}

static void
st_free_token(st_token *tok) {
    dTHX;
    if (tok->ref_cnt != 0) {
        ST_CROAK("Won't free token 0x%x with ref_cnt != 0 [%d]", 
            tok, tok->ref_cnt);
    }
    SvREFCNT_dec(tok->str);
    free(tok);
}

static void
st_free_token_list(st_token_list *token_list) {
    dTHX;
    if (token_list->ref_cnt != 0) {
        ST_CROAK("Won't free token_list 0x%x with ref_cnt > 0 [%d]", 
            token_list, token_list->ref_cnt);
    }
    SvREFCNT_dec(token_list->tokens);
    free(token_list);
}

static void
st_dump_token_list(st_token_list *tl) {
    IV len, pos;
    len = av_len(tl->tokens);
    pos = 0;
    warn("TokenList 0x%x", tl);
    warn(" pos = %d\n", tl->pos);
    warn(" len = %d\n", len + 1);
    warn(" num = %d\n", tl->num);
    warn(" ref_cnt = %d\n", tl->ref_cnt);
    while (pos < len) {
        st_dump_token((st_token*)st_extract_ptr(st_av_fetch(tl->tokens, pos++)));
    }
}

static void
st_dump_token(st_token *tok) {
    warn("Token 0x%x", tok);
    warn(" str = %s\n", SvPV(tok->str, PL_na));
    warn(" pos = %d\n", tok->pos);
    warn(" len = %d\n", tok->len);
    warn(" u8len = %d\n", tok->u8len);
    warn(" is_match = %d\n", tok->is_match);
    warn(" is_hot   = %d\n", tok->is_hot);
    warn(" ref_cnt  = %d\n", tok->ref_cnt);
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
st_dump_sv(SV* ref) {
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
            warn("  %s => %s  [%d]\n", 
                SvPV(sv_key, PL_na), SvPV(sv_val, PL_na), refcnt);
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
    st_dump_sv( object );
}


/*
    st_tokenize() et al based on KinoSearch::Analysis::Tokenizer 
    by Marvin Humphrey.
    He dared go where no XS regex user had gone before...
*/

static SV*
st_tokenize( SV* str, SV* token_re, SV* match_handler ) {
    dTHX;   /* thread-safe perlism */
    dSP;    /* callback macro */
    
/* declare */
    IV               num_tokens;
    MAGIC           *mg;
    REGEXP          *rx;
    char            *buf, *str_start, *str_end;
    STRLEN           str_len;
    const char      *prev_end, *prev_start;
    AV              *tokens;
    SV              *tok;

/* initialize */
    num_tokens      = 0;
    mg              = NULL;
    rx              = NULL;
    buf             = SvPV(str, str_len);
    str_start       = buf;
    str_end         = str_start + str_len;
    prev_start      = str_start;
    prev_end        = prev_start;
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
    
    //warn("tokenizing: '%s'\n", buf);
    
    while ( pregexec(rx, buf, str_end, buf, 1, str, 1) ) {
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
        
        /*  create token for the bytes between the last match and this one
         *  check first that we have moved past first byte 
         *  and that the regex has moved us forward at least one byte
         */
        if (start_ptr != str_start && start_ptr != prev_end) {
            token = st_new_token(num_tokens++, 
                                (start_ptr - prev_end),
                                utf8_distance((U8*)start_ptr, (U8*)prev_end),
                                prev_end, 0, 0);
            if (ST_DEBUG) {
                warn("prev [%d] [%d] [%d] [%s]", 
                    token->pos, token->len, token->u8len, SvPV(token->str, PL_na));
            }
            
            tok = st_bless_ptr(ST_CLASS_TOKEN, (IV)token);
            av_push(tokens, SvREFCNT_inc(tok));
        }
        
        /* create token object for the current match */            
        token = st_new_token(num_tokens++, 
                            (end_ptr - start_ptr),
                            utf8_distance((U8*)end_ptr, (U8*)start_ptr),
                            start_ptr,
                            0, 1);
        if (ST_DEBUG) {
            warn("[%d] [%d] [%d] [%s]", 
                token->pos, token->len, token->u8len, SvPV(token->str, PL_na));
        }
        
        tok = st_bless_ptr(ST_CLASS_TOKEN, (IV)token);
        if (match_handler != NULL) {
            PUSHMARK(SP);
            XPUSHs(tok);
            PUTBACK;
            call_sv(match_handler, G_DISCARD);
        }
        av_push(tokens, SvREFCNT_inc(tok));
        
        /* remember where we are for next time */
        prev_end = end_ptr;
        prev_start = start_ptr;
    }
    
    if (prev_end != str_end) {
        /* some bytes after the last match */
        st_token *token = st_new_token(num_tokens++, 
                                    (str_end - prev_end),
                                    utf8_distance((U8*)str_end, (U8*)prev_end),
                                    prev_end, 
                                    0, 0);
        if (ST_DEBUG) {
            warn("tail [%d] [%d] [%d] [%s]", 
                token->pos, token->len, token->u8len, SvPV(token->str, PL_na));
        }
        tok = st_bless_ptr(ST_CLASS_TOKEN, (IV)token);
        av_push(tokens, SvREFCNT_inc(tok));
    }
        
    return st_bless_ptr(
            ST_CLASS_TOKENLIST, 
            (IV)st_new_token_list(tokens, num_tokens)
           );
}

