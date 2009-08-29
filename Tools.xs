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

# TODO make handler optional
SV*
tokenize(self, str)
    SV* self;
    SV* str;
    
    PREINIT:
        SV* token_re;
        STRLEN len;
        U8* bytes;
        
    CODE:
        bytes  = (U8*)SvPV(str, len);
        if(!is_utf8_string(bytes, len)) {
            croak("str must be UTF-8 encoded. Check to_utf8() first.");
        }

        token_re = st_hvref_fetch(self, "re");
        RETVAL = st_tokenize( str, token_re );
    
    OUTPUT:
        RETVAL


############################################################################

MODULE = Search::Tools       PACKAGE = Search::Tools::TokenList

SV*
next(self)
    SV* self;
    
    PREINIT:
        SV *list;
        SV *pos;
        
    CODE:
        pos = st_hvref_fetch(self, "pos");
        
        //warn("fetching pos %d from list\n", SvIV(pos));
        list = st_hvref_fetch(self, "list");
        //st_describe_object(list);
        //warn("fetched list from object\n");
        
        if (st_hvref_fetch_as_int(self, "num") < SvIV(pos)) {
            //warn("exceeded length of array\n");
            RETVAL = &PL_sv_undef;
        }
        else {
            RETVAL = SvREFCNT_inc(st_av_fetch((AV*)SvRV(list), SvIV(pos)));
            
            // bump position
            SvIV_set(pos, SvIV(pos)+1);
            //warn("pos now == %d\n", SvIV(st_hvref_fetch(self, "pos")));
        }
        
            
    OUTPUT:
        RETVAL


############################################################################

MODULE = Search::Tools       PACKAGE = Search::Tools::Token

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
        //warn("[pos %d] [len %d] [%s]", self->pos, self->len, self->offset);
        RETVAL = newSVpvn_utf8(self->offset, self->len, 1);

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


    
    
