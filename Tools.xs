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


# end Search::Tools package
# include other .xs
INCLUDE: Tokenizer.xs
