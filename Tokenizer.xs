# Copyright 2009 Peter Karman
#
# This program is free software; you can redistribute it and/or modify
# under the same terms as Perl itself.
#

MODULE = Search::Tools       PACKAGE = Search::Tools::Tokenizer

SV*
tokenize(self, str, handler)
    SV* self;
    SV* str;
    SV* handler;
    
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
        RETVAL = st_tokenize( str, token_re, handler );
    
    OUTPUT:
        RETVAL


############################################################################

MODULE = Search::Tools       PACKAGE = Search::Tools::TokenList

SV*
next(self)
    SV* self;
            
    CODE:
        RETVAL = av_shift((AV*)SvRV(self));
        
    OUTPUT:
        RETVAL


