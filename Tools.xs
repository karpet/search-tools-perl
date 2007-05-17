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

MODULE = Search::Tools       PACKAGE = Search::Tools::UTF8

PROTOTYPES: enable

int
is_valid_utf8(string)
    SV* string;
    
    PREINIT:
        STRLEN len;
        char * bytes;
        
    CODE:
        bytes  = SvPV(string, len);
        RETVAL = is_utf8_string(bytes, len);
        
    OUTPUT:
        RETVAL
        
                

SV*
find_bad_utf8(string)
    SV* string;
    
    PREINIT:
        STRLEN len;
        char * bytes;
        U8 * pos;
        
    CODE:
        bytes  = SvPV(string, len);
        is_utf8_string_loc(bytes, len, &pos);
        RETVAL = newSVpvn(pos, strlen(pos));
        
    OUTPUT:
        RETVAL
        
