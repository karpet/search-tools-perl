/* Copyright 2009 Peter Karman
 *
 * This program is free software; you can redistribute it and/or modify
 * under the same terms as Perl itself.
 */

/*
 * Standard XS greeting.
 */
#ifdef __cplusplus
extern "C" {
#endif
#define PERL_NO_GET_CONTEXT 
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#ifdef EXTERN
  #undef EXTERN
#endif

#define EXTERN static

/* pure C helpers */
#include "search-tools.c"

/********************************************************************/

MODULE = Search::Tools       PACKAGE = Search::Tools::UTF8

PROTOTYPES: enable

int
is_perl_utf8_string(string)
    SV* string;
    
    PREINIT:
        STRLEN len;
        U8 * bytes;
        
    CODE:
        bytes  = (U8*)SvPV(string, len);
        RETVAL = is_utf8_string(bytes, len);
        
    OUTPUT:
        RETVAL
        
                

SV*
find_bad_utf8(string)
    SV* string;
    
    PREINIT:
        STRLEN len;
        U8 * bytes;
        const U8 * pos;  // gives warnings in perl < 5.8.9
        
    CODE:
        bytes  = (U8*)SvPV(string, len);
        if (is_utf8_string(bytes, len))
        {
            RETVAL = &PL_sv_undef;
        }
        else
        {
            is_utf8_string_loc(bytes, len, &pos);
            RETVAL = newSVpvn((char*)pos, strlen((char*)pos));
        }

    OUTPUT:
        RETVAL
        
# benchmarks show these XS versions are 9x faster
# than their native Perl regex counterparts
int 
is_ascii(string)
    SV* string;
    
    PREINIT:
        STRLEN          len;
        unsigned char*  bytes;
        unsigned int    i;
        
    CODE:
        bytes  = (unsigned char*)SvPV(string, len);
        RETVAL = 1;
        for(i=0; i < len; i++)
        {
            if (bytes[i] >= 0x80)
            {
                RETVAL = 0;
                break;
            }  
        }

    OUTPUT:
        RETVAL
    
int
is_latin1(string)
    SV* string;

    PREINIT:
        STRLEN         len;
        unsigned char* bytes;
        unsigned int   i;

    CODE:
        bytes  = (unsigned char*)SvPV(string, len);
        RETVAL = 1;
        for(i=0; i < len; i++)
        {
            if (bytes[i] > 0x7f && bytes[i] < 0xa0)
            {
                RETVAL = 0;
                break;
            }
        }

    OUTPUT:
        RETVAL


int
find_bad_ascii(string)
    SV* string;
    
    PREINIT:
        STRLEN          len;
        unsigned char*  bytes;
        int             i;
        
    CODE:
        bytes  = (unsigned char*)SvPV(string, len);
        RETVAL = -1;
        for(i=0; i < len; i++)
        {
            if (bytes[i] >= 0x80)
            {
            # return $+[0], so base-1
                RETVAL = i + 1;
                break;
            }  
        }

    OUTPUT:
        RETVAL

int
find_bad_latin1(string)
    SV* string;

    PREINIT:
        STRLEN          len;
        unsigned char*  bytes;
        int             i;

    CODE:
        bytes  = (unsigned char*)SvPV(string, len);
        RETVAL = -1;
        for(i=0; i < len; i++)
        {
            if (bytes[i] > 0x7f && bytes[i] < 0xa0)
            {
            # return $+[0], so base-1
                RETVAL = i + 1;
                break;
            }
        }

    OUTPUT:
        RETVAL



#############################################################################

MODULE = Search::Tools       PACKAGE = Search::Tools::Tokenizer

PROTOTYPES: enable

SV*
tokenize(self, str, ...)
    SV* self;
    SV* str;
    
    PREINIT:
        SV* token_re;
        STRLEN len;
        U8* bytes;
        SV* match_handler = NULL;
        
    CODE:
        if (items > 2) {
            match_handler = ST(2);
        }
        
        /* test if utf8 flag on and make sure it is.
         * otherwise, regex for \w can fail for multibyte chars.
         */
        if (!SvUTF8(str)) {
            bytes  = (U8*)SvPV(str, len);
            if(!is_utf8_string(bytes, len)) {
                croak(ST_BAD_UTF8);
            }
            SvUTF8_on(str);
        }

        token_re = st_hvref_fetch(self, "re");
        RETVAL = SvREFCNT_inc(st_tokenize(str, token_re, match_handler));
    
    OUTPUT:
        RETVAL

void
set_debug(self, val)
    SV* self;
    boolean val;
    
    CODE:
        ST_DEBUG = val;



############################################################################

MODULE = Search::Tools       PACKAGE = Search::Tools::TokenList

PROTOTYPES: enable

void
dump(self)
    st_token_list *self;
    
    CODE:
        st_dump_token_list(self);


SV*
next(self)
    st_token_list *self;
   
    PREINIT:
        IV len;
        
    CODE:
        len = av_len(self->tokens);
        if (len == -1) {
            // empty list
            RETVAL = &PL_sv_undef;
        }
        else if (self->pos > len) {
            // exceeded end of list
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = SvREFCNT_inc(st_av_fetch(self->tokens, self->pos++));
        }
        
            
    OUTPUT:
        RETVAL


SV*
prev(self)
    st_token_list *self;
   
    PREINIT:
        IV len;
        
    CODE:
        len = av_len(self->tokens);
        if (len == -1) {
            // empty list
            RETVAL = &PL_sv_undef;
        }
        else if (self->pos < 0) {
            // exceeded start of list
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = SvREFCNT_inc(st_av_fetch(self->tokens, --(self->pos)));
        }
        
            
    OUTPUT:
        RETVAL


SV*
get_token(self, pos)
    st_token_list *self;
    IV pos;
    
    CODE:
        if (!av_exists(self->tokens, pos)) {
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = SvREFCNT_inc(st_av_fetch(self->tokens, pos));
        }
    
    OUTPUT:
        RETVAL


IV
set_pos(self, new_pos)
    st_token_list *self;
    IV  new_pos;
            
    CODE:
        RETVAL = self->pos;
        self->pos = new_pos;
       
    OUTPUT:
        RETVAL


IV
reset_pos(self)
    st_token_list *self;
        
    CODE:
        RETVAL = self->pos;
        self->pos = 0;
    
    OUTPUT:
        RETVAL
 

IV
len(self)
    st_token_list *self;
    
    CODE:
        RETVAL = av_len(self->tokens) + 1;
        
    OUTPUT:
        RETVAL


IV
num(self)
    st_token_list *self;
    
    CODE:
        RETVAL = self->num;
    
    OUTPUT:
        RETVAL


IV
pos(self)
    st_token_list *self;
    
    CODE:
        RETVAL = self->pos;
    
    OUTPUT:
        RETVAL


SV*
as_array(self)
    st_token_list *self;
    
    CODE:
        RETVAL = newRV_inc((SV*)self->tokens);
    
    OUTPUT:
        RETVAL


SV*
matches(self)
    st_token_list *self;
    
    PREINIT:
        AV *matches;
        IV pos;
        IV len;
        SV* tok;
        st_token *token;
    
    CODE:
        matches = newAV();
        pos = 0;
        len = av_len(self->tokens);
        while (pos < len) {
            tok = st_av_fetch(self->tokens, pos++);
            token = (st_token*)st_extract_ptr(tok);
            if (token->is_match) {
                av_push(matches, SvREFCNT_inc(tok));
            }
        }
        RETVAL = newRV((SV*)matches); /* no _inc -- this is only copy */
    
    OUTPUT:
        RETVAL


void
DESTROY(self)
    SV *self;
    
    PREINIT:
        st_token_list *tl;
        
    CODE:
        
        
        tl = (st_token_list*)st_extract_ptr(self);
        tl->ref_cnt--;
        if (ST_DEBUG) {
            warn("............................");
            warn("DESTROY %s [%d] [0x%x]\n", 
                SvPV(self, PL_na), tl->ref_cnt, tl);
            st_describe_object(self);
            st_dump_sv((SV*)tl->tokens);
        }
        if (tl->ref_cnt < 1) {
            st_free_token_list(tl);
        }



############################################################################

MODULE = Search::Tools       PACKAGE = Search::Tools::Token

PROTOTYPES: enable

IV
pos(self)
    st_token *self;
    
    CODE:
        RETVAL = self->pos;
    
    OUTPUT:
        RETVAL


SV*
str(self)
    st_token *self;
            
    CODE:
        RETVAL = SvREFCNT_inc(self->str);

    OUTPUT:
        RETVAL


IV
len(self)
    st_token *self;
    
    CODE:
        RETVAL = self->len;
    
    OUTPUT:
        RETVAL


IV
u8len(self)
    st_token *self;
    
    CODE:
        RETVAL = self->u8len;
    
    OUTPUT:
        RETVAL


IV
is_hot(self)
    st_token *self;
    
    CODE:
        RETVAL = self->is_hot;
    
    OUTPUT:
        RETVAL


IV
is_match(self)
    st_token *self;
    
    CODE:
        RETVAL = self->is_match;
    
    OUTPUT:
        RETVAL


IV
set_match(self, val)
    st_token *self;
    IV val;
    
    CODE:
        RETVAL = self->is_match;
        self->is_match = val;
    
    OUTPUT:
        RETVAL


IV
set_hot(self, val)
    st_token *self;
    IV val;
    
    CODE:
        RETVAL = self->is_hot;
        self->is_hot = val;
    
    OUTPUT:
        RETVAL


void
dump(self)
    st_token *self;
    
    CODE:
        st_dump_token(self);


void
DESTROY(self)
    SV *self;
    
    PREINIT:
        st_token *tok;
        
    CODE:
        tok = (st_token*)st_extract_ptr(self);
        tok->ref_cnt--;
        if (ST_DEBUG) {
            warn("............................");
            warn("DESTROY %s [%d] [0x%x]\n", 
                SvPV(self, PL_na), tok->ref_cnt, tok);
        }
        if (tok->ref_cnt < 1) {
            st_free_token(tok);
        }
    
