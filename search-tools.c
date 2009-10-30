/* Copyright 2009 Peter Karman
 *
 * This program is free software; you can redistribute it and/or modify
 * under the same terms as Perl itself.
 */

/*
 * Search::Tools C helpers
 */
 
#include <wctype.h>
#include "search-tools.h"

/* global debug var */
static boolean ST_DEBUG = 0;

/* perl versions < 5.8.8 do not have this */
#ifndef is_utf8_string_loclen
bool
is_utf8_string_loclen(const U8 *s, STRLEN len, const U8 **ep, STRLEN *el)
{
    dTHX;
    const U8* x = s;
    const U8* send;
    STRLEN c;

    if (!len)
        len = strlen((const char *)s);
    send = s + len;
    if (el)
        *el = 0;

    while (x < send) {
         /* Inline the easy bits of is_utf8_char() here for speed... */
         if (UTF8_IS_INVARIANT(*x))
             c = 1;
         else if (!UTF8_IS_START(*x))
             goto out;
         else {
             /* ... and call is_utf8_char() only if really needed. */
#ifdef IS_UTF8_CHAR
             c = UTF8SKIP(x);
             if (IS_UTF8_CHAR_FAST(c)) {
                 if (!IS_UTF8_CHAR(x, c))
                     c = 0;
             } else
                 c = is_utf8_char_slow(x, c);
#else
             c = is_utf8_char(x);
#endif /* #ifdef IS_UTF8_CHAR */
             if (!c)
                 goto out;
         }
         x += c;
         if (el)
             (*el)++;
    }

 out:
    if (ep)
        *ep = x;
    if (x != send)
        return FALSE;

    return TRUE;
}

#endif
 

/* UNUSED
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
*/
/* UNUSED
static SV*
st_hv_store_char( HV* h, const char *key, char *val) {
    dTHX;
    SV *value;
    value = newSVpv(val, 0);
    st_hv_store( h, key, value );
    SvREFCNT_dec(value);
    return value;
}
*/
/* UNUSED
static SV*      
st_hv_store_int( HV* h, const char* key, int i) {
    dTHX;
    SV *value;
    value = newSViv(i);
    st_hv_store( h, key, value );
    SvREFCNT_dec(value);
    return value;
}
*/
/* UNUSED
static SV*
st_hvref_store( SV* h, const char* key, SV* val) {
    dTHX;
    return st_hv_store( (HV*)SvRV(h), key, val );
}
*/
/* UNUSED
static SV*
st_hvref_store_char( SV* h, const char* key, char *val) {
    dTHX;
    return st_hv_store_char( (HV*)SvRV(h), key, val );
}
*/
/*  UNUSED
static SV*
st_hvref_store_int( SV* h, const char* key, int i) {
    dTHX;
    return st_hv_store_int( (HV*)SvRV(h), key, i );
}
*/

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

static IV
st_av_fetch_ptr( AV* a, I32 index ) {
    dTHX;
    SV** ok;
    IV ptr;
    ok = av_fetch(a, index, 0);
    if (ok == NULL) {
        ST_CROAK("failed to fetch index %d", index);
    }
    ptr = st_extract_ptr(*ok);
    //warn("%s refcnt == %d", SvPV_nolen(*ok), SvREFCNT(*ok));
    return ptr;
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

/* UNUSED
static char*
st_hv_fetch_as_char( HV* h, const char* key ) {
    dTHX;
    SV** ok;
    ok = hv_fetch(h, key, strlen(key), 0);
    if (ok == NULL) {
        ST_CROAK("failed to fetch %s from hash", key);
    }
    return SvPV_nolen((SV*)*ok);
}
*/
/* UNUSED
static char*
st_hvref_fetch_as_char( SV* h, const char* key ) {
    dTHX;
    return st_hv_fetch_as_char( (HV*)SvRV(h), key );
}
*/
/* UNUSED
static IV
st_hvref_fetch_as_int( SV* h, const char* key ) {
    dTHX;
    SV* val;
    IV i;
    val = st_hv_fetch( (HV*)SvRV(h), key );
    i = SvIV(val);
    return i;
}
*/

void *
st_malloc(size_t size) {
    dTHX;
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
    I32 pos, 
    I32 len,
    I32 u8len,
    const char *ptr,
    I32 is_hot,
    boolean is_match
) {
    dTHX;
    st_token *tok;
    
    if (!len) {
        ST_CROAK("cannot create token with zero length: '%s'", ptr);
    }
    
    tok = st_malloc(sizeof(st_token));
    tok->pos = pos;
    tok->len = len;
    tok->u8len = u8len;
    tok->is_hot = is_hot;
    tok->is_match = is_match;
    tok->is_sentence_start = 0;
    tok->is_sentence_end = 0;
    tok->str = newSVpvn(ptr, len); /* newSVpvn_utf8 not available in some perls? */
    SvUTF8_on(tok->str);
    tok->ref_cnt = 1;
    return tok;
}

static st_token_list*
st_new_token_list(
    AV *tokens,
    AV *heat,
    AV *sentence_starts,
    unsigned int num
) {
    dTHX;
    st_token_list *tl;
    tl = st_malloc(sizeof(st_token_list));
    tl->pos = 0;
    tl->tokens = tokens;
    tl->heat   = heat;
    tl->sentence_starts = sentence_starts;
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
    
    //warn("about to free st_token_list C struct\n");
    //st_dump_token_list(token_list);

    SvREFCNT_dec(token_list->tokens);
    if (SvREFCNT(token_list->tokens)) {
        warn("Warning: possible memory leak for token_list->tokens 0x%lx with REFCNT %d\n", 
            (unsigned long)token_list->tokens, SvREFCNT(token_list->tokens));
    }
    
    SvREFCNT_dec(token_list->heat);
    if (SvREFCNT(token_list->heat)) {
        warn("Warning: possible memory leak for token_list->heat 0x%lx with REFCNT %d\n", 
            (unsigned long)token_list->heat, SvREFCNT(token_list->heat));
    }

    SvREFCNT_dec(token_list->sentence_starts);
    if (SvREFCNT(token_list->sentence_starts)) {
        warn("Warning: possible memory leak for token_list->sentence_starts 0x%lx with REFCNT %d\n", 
            (unsigned long)token_list->sentence_starts, SvREFCNT(token_list->sentence_starts));
    }

    free(token_list);
}

static void
st_dump_token_list(st_token_list *tl) {
    dTHX;
    IV len, pos;
    SV* tok;
    len = av_len(tl->tokens);
    pos = 0;
    warn("TokenList 0x%lx", (unsigned long)tl);
    warn(" pos = %ld\n", (unsigned long)tl->pos);
    warn(" len = %ld\n", (unsigned long)len + 1);
    warn(" num = %ld\n", (unsigned long)tl->num);
    warn(" ref_cnt = %ld\n", (unsigned long)tl->ref_cnt);
    warn(" tokens REFCNT = %ld\n", (unsigned long)SvREFCNT(tl->tokens));
    warn(" heat REFCNT = %ld\n", (unsigned long)SvREFCNT(tl->heat));
    warn(" sen_starts REFCNT = %ld\n", (unsigned long)SvREFCNT(tl->sentence_starts));
    while (pos < len) {
        tok = st_av_fetch(tl->tokens, pos++);
        warn("  Token REFCNT = %ld\n", (unsigned long)SvREFCNT(tok));
        st_dump_token((st_token*)st_extract_ptr(tok));
    }
}

static void
st_dump_token(st_token *tok) {
    dTHX;
    warn("Token 0x%lx", (unsigned long)tok);
    warn(" str = '%s'\n", SvPV_nolen(tok->str));
    warn(" pos = %ld\n", (unsigned long)tok->pos);
    warn(" len = %ld\n", (unsigned long)tok->len);
    warn(" u8len = %ld\n", (unsigned long)tok->u8len);
    warn(" is_match = %d\n", tok->is_match);
    warn(" is_sentence_start = %d\n", tok->is_sentence_start);
    warn(" is_sentence_end   = %d\n", tok->is_sentence_end);
    warn(" is_hot   = %d\n", tok->is_hot);
    warn(" ref_cnt  = %ld\n", (unsigned long)tok->ref_cnt);
}

/* make a Perl blessed object from a C pointer */
static SV* 
st_bless_ptr( const char *class, IV c_ptr ) {
    dTHX;
    SV* obj = newSViv(c_ptr);
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
    dTHX;
    va_list args;
    va_start(args, msgfmt);
    warn("Search::Tools error at %s:%d %s: ", file, line, func);
    //warn(msgfmt, args);
    croak(msgfmt, args);
    /* NEVER REACH HERE */
    va_end(args);
}

/* UNUSED
static SV*
st_new_hash_object(const char *class) {
    dTHX;
    HV *hash;
    SV *object;
    hash    = newHV();
    object  = sv_bless( newRV((SV*)hash), gv_stashpv(class,0) );
    return object;
}
*/

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
                SvPV_nolen(sv_key), SvPV_nolen(sv_val), refcnt);
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
    str = SvPV_nolen( object );
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

static boolean
st_is_ascii( SV* str ) {
    dTHX;
    STRLEN len;
    U8 *bytes;
    IV i;
    
    bytes = (U8*)SvPV(str, len);
    for(i=0; i<len; i++) {
        if (bytes[i] >= 0x80) {
            return 0;
        }  
    }
    return 1;
}

static REGEXP*
st_get_regex_from_sv( SV *regex_sv ) {
    dTHX;   /* thread-safe perlism */
    MAGIC *mg;
    mg = NULL;

    /* extract regexp struct from qr// entity */
    if (SvROK(regex_sv)) {
        SV *sv = SvRV(regex_sv);
        if (SvMAGICAL(sv))
            mg = mg_find(sv, PERL_MAGIC_qr);
    }
    if (!mg)
        ST_CROAK("regex is not a qr// entity");
        
    return (REGEXP*)mg->mg_obj;
}

static void
st_heat_seeker( st_token *token, SV *re ) {
    dTHX;   /* thread-safe perlism */
    
    REGEXP *rx;
    char *buf, *str_end;
    
    rx = st_get_regex_from_sv(re);
    buf = SvPVX(token->str);
    str_end = buf + token->len;

    if ( pregexec(rx, buf, str_end, buf, 1, token->str, 1) ) {
        if (ST_DEBUG > 1) {
            warn("st_heat_seeker: token is hot: %s", buf);
        }
        token->is_hot = 1;
    }

}

/*
    st_tokenize() et al based on KinoSearch::Analysis::Tokenizer 
    by Marvin Humphrey.
    He dared go where no XS regex user had gone before...
*/

static SV*
st_tokenize( SV* str, SV* token_re, SV* heat_seeker, I32 match_num ) {
    dTHX;   /* thread-safe perlism */
    dSP;    /* callback macro */
    
/* declare */
    IV               num_tokens, prev_sentence_start;
    REGEXP          *rx;
    char            *buf, *str_start, *str_end, *token_str;
    STRLEN           str_len;
    const char      *prev_end, *prev_start;
    AV              *tokens;
    AV              *heat;
    AV              *sentence_starts;
    SV              *tok;
    boolean          heat_seeker_is_CV;

/* initialize */
    num_tokens      = 0;
    rx              = st_get_regex_from_sv(token_re);
    buf             = SvPV(str, str_len);
    str_start       = buf;
    str_end         = str_start + str_len;
    prev_start      = str_start;
    prev_end        = prev_start;
    tokens          = newAV();
    heat            = newAV();
    sentence_starts = newAV();
    prev_sentence_start = 0;
    heat_seeker_is_CV  = 0;
    if (heat_seeker != NULL && (SvTYPE(SvRV(heat_seeker))==SVt_PVCV)) {
         heat_seeker_is_CV = 1;
    }
    
    if (ST_DEBUG) {    
        warn("tokenizing string %ld bytes long\n", str_len);
    }
    
    while ( pregexec(rx, buf, str_end, buf, 1, str, 1) ) {
        const char *start_ptr, *end_ptr;
        st_token *token;
        
#if ((PERL_VERSION > 9) || (PERL_VERSION == 9 && PERL_SUBVERSION >= 5))
        start_ptr = buf + rx->offs[match_num].start;
        end_ptr   = buf + rx->offs[match_num].end;
#else
        start_ptr = buf + rx->startp[match_num];
        end_ptr   = buf + rx->endp[match_num];
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
            token_str = SvPV_nolen(token->str);
            if (st_looks_like_sentence_start(token_str, token->len)) {
                token->is_sentence_start = 1;
            }
            else if (st_looks_like_sentence_end(token_str, token->len)) {
                token->is_sentence_end = 1;
            }
            if (ST_DEBUG > 1) {
                warn("prev [%d] [%d] [%d] [%s] [%d] [%d]", 
                    token->pos, token->len, token->u8len, token_str,
                    token->is_sentence_start, token->is_sentence_end);
            }
            
            tok = st_bless_ptr(ST_CLASS_TOKEN, (IV)token);
            av_push(tokens, tok);
            if (token->is_sentence_start) {
                //av_push(sentence_starts, newSViv(token->pos));
                prev_sentence_start = token->pos;
            }
        }
        
        /* create token object for the current match */            
        token = st_new_token(num_tokens++, 
                            (end_ptr - start_ptr),
                            utf8_distance((U8*)end_ptr, (U8*)start_ptr),
                            start_ptr,
                            0, 1);
        token_str = SvPV_nolen(token->str);
        if (st_looks_like_sentence_start(token_str, token->len)) {
            token->is_sentence_start = 1;
        }
        else if (st_looks_like_sentence_end(token_str, token->len)) {
            token->is_sentence_end = 1;
        }
        if (ST_DEBUG > 1) {
            warn("main [%d] [%d] [%d] [%s] [%d] [%d]", 
                token->pos, token->len, token->u8len, token_str,
                token->is_sentence_start, token->is_sentence_end
            );
        }
        
        tok = st_bless_ptr(ST_CLASS_TOKEN, (IV)token);
        if (heat_seeker != NULL) {
            if (heat_seeker_is_CV) {
                PUSHMARK(SP);
                XPUSHs(tok);
                PUTBACK;
                call_sv(heat_seeker, G_DISCARD);
            }
            else {
                st_heat_seeker(token, heat_seeker);
            }
        }
        av_push(tokens, tok);
        if (token->is_sentence_start) {
            //av_push(sentence_starts, newSViv(token->pos));
            prev_sentence_start = token->pos;
        }
        if (token->is_hot) {
            av_push(heat, newSViv(token->pos));
            if (ST_DEBUG)
                warn("%s: sentence_start = %ld for hot token at pos %ld\n",
                    __func__, (unsigned long)prev_sentence_start, (unsigned long)token->pos);
                    
            av_push(sentence_starts, newSViv(prev_sentence_start));
        }
        
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
        token_str = SvPV_nolen(token->str);
        if (st_looks_like_sentence_start(token_str, token->len)) {
            token->is_sentence_start = 1;
        }
        else if (st_looks_like_sentence_end(token_str, token->len)) {
            token->is_sentence_end = 1;
        }
        if (ST_DEBUG > 1) {
            warn("tail: [%d] [%d] [%d] [%s] [%d] [%d]", 
                token->pos, token->len, token->u8len, token_str,
                token->is_sentence_start, token->is_sentence_end
            );
        }

        tok = st_bless_ptr(ST_CLASS_TOKEN, (IV)token);
        av_push(tokens, tok);
    }
        
    return st_bless_ptr(
            ST_CLASS_TOKENLIST, 
            (IV)st_new_token_list(tokens, heat, sentence_starts, num_tokens)
           );
}

static SV*
st_find_bad_utf8( SV* str ) {
    dTHX;
    
    STRLEN len;
    U8 *bytes;
    const U8 *pos;
    STRLEN *el;

    bytes   = (U8*)SvPV(str, len);
    el      = 0;
    if (is_utf8_string(bytes, len)) {
        return &PL_sv_undef;
    }
    else {
        is_utf8_string_loclen(bytes, len, &pos, el);
        return newSVpvn((char*)pos, strlen((char*)pos));
    }
}

/* lifted nearly verbatim from mod_perl */
static SV *st_escape_xml(char *s) {
    dTHX;

    int i, j;
    SV *x;

    /* first, count the number of extra characters */
    for (i = 0, j = 0; s[i] != '\0'; i++)
        if (s[i] == '<' || s[i] == '>')
            j += 3;
        else if (s[i] == '&')
            j += 4;
        else if (s[i] == '"' || s[i] == '\'')
            j += 5;

    if (j == 0)
        return newSVpv(s,i);

    x = newSV(i + j + 1);

    for (i = 0, j = 0; s[i] != '\0'; i++, j++)
    if (s[i] == '<') {
        memcpy(&SvPVX(x)[j], "&lt;", 4);
        j += 3;
    }
    else if (s[i] == '>') {
        memcpy(&SvPVX(x)[j], "&gt;", 4);
        j += 3;
    }
    else if (s[i] == '&') {
        memcpy(&SvPVX(x)[j], "&amp;", 5);
        j += 4;
    }
    else if (s[i] == '"') {
        memcpy(&SvPVX(x)[j], "&quot;", 6);
        j += 5;
    }
    else if (s[i] == '\'') {
        memcpy(&SvPVX(x)[j], "&apos;", 6);
        j += 5;
    }
    else
        SvPVX(x)[j] = s[i];

    SvPVX(x)[j] = '\0';
    SvCUR_set(x, j);
    SvPOK_on(x);
    return x;
}

/* returns the UCS32 value for a UTF8 string -- the character's Unicode value.
   see http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&item_id=IWS-AppendixA
*/
static IV
st_utf8_codepoint(
    const unsigned char *utf8,
    IV len
)
{
    dTHX;
    
    switch (len) {

    case 1:
        return utf8[0];

    case 2:
        return (utf8[0] - 192) * 64 + utf8[1] - 128;

    case 3:
        return (utf8[0] - 224) * 4096 + (utf8[1] - 128) * 64 + utf8[2] - 128;

    case 4:
    default:
        return (utf8[0] - 240) * 262144 + (utf8[1] - 128) * 4096 + (utf8[2] - 128) * 64 +
            utf8[3] - 128;

    }
}

static IV
st_looks_like_sentence_start(const unsigned char *ptr, IV len) {
    dTHX;
    
    I32 u8len, u32pt;
    
    if (ST_DEBUG > 1)
        warn("%s: %c\n", __func__, ptr[0]); 
    
    /* optimized for ASCII */
    if (ptr[0] < 128) {
        return isUPPER(ptr[0]);
    }
    
    /* TODO if any char is UPPER in the string, consider it a start? */
    
    /* get first full UTF-8 char */
    u8len = is_utf8_char((U8*)ptr);
    if (ST_DEBUG > 1)
        warn("%s: %s is utf8 u8len %d\n", __func__, ptr, u8len);
    
    if (len) {
        u32pt = st_utf8_codepoint(ptr, u8len);
        
        if (ST_DEBUG > 1)
            warn("%s: u32 code point %d\n", __func__, u32pt);
        
        if (iswupper((wint_t)u32pt)) {
            return 1;
        }
        if (u32pt == 191) { /* INVERTED QUESTION MARK */
            return 1;
        }
        
        /* TODO more here? */
        
        return 0;
    }
    return 0;
}

/* does any char in the string look like a sentence ending? */
static IV
st_looks_like_sentence_end(const unsigned char *ptr, IV len) {
    dTHX;
    
    IV i;
    
    /* right now this assumes ASCII sentence punctuation.
     * if we ever wanted utf8 support we'd need to iterate
     * per-character instead of per byte.
     */
    
    if (ST_DEBUG > 1)
        warn("%s: %c\n", __func__, ptr[0]);
    
    for (i=0; i<len; i++) {
        switch (ptr[i]) {
            case '.':
                return 1;
                break;
            
            case '?':
                return 1;
                break;
            
            case '!':
                return 1;
                break;
                
            case ';':   /* TODO ? */
                return 1;
                break;
                
            default:
                continue;
                
        }
    }
    return 0;
}

