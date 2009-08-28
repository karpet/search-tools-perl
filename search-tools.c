/* Copyright 2009 Peter Karman
 *
 * This program is free software; you can redistribute it and/or modify
 * under the same terms as Perl itself.
 */

/*
 * C helpers
 */

static SV*      st_hv_store( HV* h, const char* key, SV* val );
static SV*      st_hv_store_char( HV* h, const char* key, char *val );
static SV*      st_hv_store_int( HV* h, const char* key, int i);
static SV*      st_hvref_store_int( SV* h, const char* key, int i);
static SV*      st_hvref_store( SV* h, const char* key, SV* val );
static SV*      st_hvref_store_char( SV* h, const char* key, char *val );
static SV*      st_hv_fetch( HV* h, const char* key );
static SV*      st_hvref_fetch( SV* h, const char* key );
static char*    st_hv_fetch_as_char( HV* h, const char* key );
static char*    st_hvref_fetch_as_char( SV* h, const char* key );
static SV*      st_tokenize( SV* str, SV* token_re, SV* handler );
static SV*      st_new_hash_object(const char *class);
static SV*      st_new_array_object(const char *class);
static SV*
st_new_token(
    char *str_start, 
    const char *start_ptr,
    const char *prev_end, 
    unsigned int token_len, 
    unsigned int offset
);

/* store SV* in a hash, incrementing its refcnt */
static SV*
sp_hv_store( HV* h, const char* key, SV* val) {
    dTHX;
    SV** ok;
    ok = hv_store(h, key, strlen(key), SvREFCNT_inc(val), 0);
    if (ok == NULL) {
        croak("failed to store %s in hash", key);
    }
    return *ok;
}

static SV*
sp_hv_store_char( HV* h, const char *key, char *val) {
    dTHX;
    SV *value;
    value = newSVpv(val, 0);
    sp_hv_store( h, key, value );
    SvREFCNT_dec(value);
    return value;
}

static SV*      
st_hv_store_int( HV* h, const char* key, int i) {
    dTHX;
    SV *value;
    value = newSViv(i);
    sp_hv_store( h, key, value );
    SvREFCNT_dec(value);
    return value;
}

static SV*
st_hvref_store( SV* h, const char* key, SV* val) {
    dTHX;
    return sp_hv_store( (HV*)SvRV(h), key, val );
}

static SV*
st_hvref_store_char( SV* h, const char* key, char *val) {
    dTHX;
    return sp_hv_store_char( (HV*)SvRV(h), key, val );
}

static SV*
st_hvref_store_int( SV* h, const char* key, int i) {
    dTHX;
    return st_hv_store_int( (HV*)SvRV(h), key, i );
}

/* fetch SV* from hash */
static SV*
st_hv_fetch( HV* h, const char* key ) {
    dTHX; /* thread-safe perlism */
    SV** ok;
    ok = hv_fetch(h, key, strlen(key), 0);
    if (ok == NULL) {
        croak("failed to fetch %s", key);
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
        croak("failed to fetch %s from hash", key);
    }
    return SvPV((SV*)*ok, PL_na);
}

static char*
st_hvref_fetch_as_char( SV* h, const char* key ) {
    dTHX;
    return st_hv_fetch_as_char( (HV*)SvRV(h), key );
}


static SV*
st_new_token(
    char *str_start, 
    const char *start_ptr,
    const char *prev_end,
    unsigned int token_len, 
    unsigned int offset
) {
    dTHX; /* thread-safe perlism */
    SV* token;
    token = st_new_hash_object("Search::Tools::Token");
    st_hvref_store(token, "str", newSVpvn_utf8(start_ptr, token_len, 1));
    st_hvref_store(token, "prev", newSVpvn_utf8(prev_end, (start_ptr - prev_end), 1));
    st_hvref_store_int(token, "len", token_len);
    st_hvref_store_int(token, "offset", offset);
    warn("token: '%s'\n", st_hvref_fetch_as_char(token, "str"));
    return token; 
}

/*
    st_tokenize() et al based on KinoSearch::Analysis::Tokenizer 
    by Marvin Humphrey.
    He dared go where no XS regex user had gone before...
*/

SV*
st_tokenize( SV* str, SV* token_re, SV* handler ) {
    dTHX; /* thread-safe perlism */
    dSP; /* stack macro */
    
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
    const char      *prev_end;
    AV              *token_list;

/* initialize */
    num_tokens      = 0;
    mg              = NULL;
    rx              = NULL;
    wrapper         = sv_newmortal();
    buf             = SvPV(str, PL_na);
    str_start       = buf;
    str_len         = strlen(buf);
    str_end         = str_start + str_len;
    prev_end        = buf;
    offset          = 0;
    token_list      = newAV();
    
/* extract regexp struct from qr// entity */
    if (SvROK(token_re)) {
        SV *sv = SvRV(token_re);
        if (SvMAGICAL(sv))
            mg = mg_find(sv, PERL_MAGIC_qr);
    }
    if (!mg)
        croak("regex is not a qr// entity");
        
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
    
    warn("tokenizing: '%s'\n", buf);
    
    while ( pregexec(rx, buf, str_end, buf, 1, wrapper, 1) ) 
    {
        unsigned int token_len;
        const char *start_ptr, *end_ptr;
        SV* token;
        
#if ((PERL_VERSION > 9) || (PERL_VERSION == 9 && PERL_SUBVERSION >= 5))
        start_ptr = buf + rx->offs[0].start;
        end_ptr   = buf + rx->offs[0].end;
#else
        start_ptr = buf + rx->startp[0];
        end_ptr   = buf + rx->endp[0];
#endif

        buf       = end_ptr;
        token_len = (end_ptr - start_ptr);
        offset    = start_ptr - str_start;
                
        warn("Token: %s [%d] [%d]", start_ptr, token_len, offset);
            
        token = st_new_token(str_start, start_ptr, prev_end, token_len, offset);
            
        PUSHMARK(SP);
        XPUSHs(token);
        PUTBACK;

        call_sv(handler, G_DISCARD);
        
        av_push(token_list, token);
        
        num_tokens++;
        
        /* remember where we are for next time */
        prev_end = end_ptr;
    }
    
    if (prev_end != str_end) {
        warn("remainder: '%s'\n", prev_end);
    }
    
    return sv_bless( newRV((SV*)token_list), gv_stashpv("Search::Tools::TokenList",0) );
    
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
