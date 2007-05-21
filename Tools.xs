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

/* C space */

/* UTF8 help from http://cprogramming.com/tutorial/unicode.html  */

/* is c the start of a utf8 sequence? */
#define isutf(c) (((c)&0xC0)!=0x80)

static const u_int32_t offsetsFromUTF8[6] = {
    0x00000000UL, 0x00003080UL, 0x000E2080UL,
    0x03C82080UL, 0xFA082080UL, 0x82082080UL
};

static const char trailingBytesForUTF8[256] = {
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, 3,3,3,3,3,3,3,3,4,4,4,4,5,5,5,5
};

/* returns length of next utf-8 sequence */
static int u8_seqlen(char *s)
{
    return trailingBytesForUTF8[(unsigned int)(unsigned char)s[0]] + 1;
}

/* reads the next utf-8 sequence out of a string, updating an index */
static u_int32_t u8_nextchar(char *s, int *i)
{
    u_int32_t ch = 0;
    int sz = 0;

    do {
        ch <<= 6;
        ch += (unsigned char)s[(*i)++];
        sz++;
    } while (s[*i] && !isutf(s[*i]));
    ch -= offsetsFromUTF8[sz-1];

    return ch;
}

/* number of characters */
static int u8_strlen(char *s)
{
    int count = 0;
    int i = 0;

    while (u8_nextchar(s, &i) != 0)
        count++;

    return count;
}

/* increment forward, updating index */
static void u8_inc(char *s, int *i)
{
    (void)(isutf(s[++(*i)]) || isutf(s[++(*i)]) ||
           isutf(s[++(*i)]) || ++(*i));
}

/* increment backward, updating index */
static void u8_dec(char *s, int *i)
{
    (void)(isutf(s[--(*i)]) || isutf(s[--(*i)]) ||
           isutf(s[--(*i)]) || --(*i));
}


/* returns number of bytes we should snip for prev_fragment.

    *s is entire string we're snipping from
    cur_index is the index of the start of the match
    max_chars is number of seqs, NOT bytes
    
*/
static int prev_frag_index(char *s, int cur_index, int max_chars)
{
    int byte_pos, prev_pos, clen, count;
    
    /* are we at the beginning? */
    if(cur_index == 0)
        return 0;
        
    count    = 0;
    prev_pos = cur_index;
    for(byte_pos = cur_index; byte_pos >= 0; u8_dec(s, &byte_pos))
    {
        clen = prev_pos - byte_pos;
        if (!clen)
        {
            prev_pos = byte_pos;
            continue;
        }
    
        if(count++ > max_chars)
            break;
                        
        prev_pos = byte_pos;
           
    }
    
    /* now forward to the first whitespace char */
    while(!isspace(s[byte_pos]))
        byte_pos++;
        
    /* and then one more to skip past it */
    byte_pos++;
        
    return byte_pos;
}

/* returns number of bytes we should snip for next_fragment.

    *s is entire string we're snipping from
    cur_index is the index of the end of the match
    max_chars is number of seqs, NOT bytes
    
*/
static int next_frag_index(char *s, int cur_index, int max_chars)
{
    int byte_pos, prev_pos, clen, count;
    
    /* are we at the end? */
    if(s[cur_index + 1] == NULL)
        return 0;
        
    count    = 0;
    prev_pos = cur_index;
    for(byte_pos = cur_index; s[prev_pos] != NULL; u8_inc(s, &byte_pos))
    {
        clen = byte_pos - prev_pos;
        if (!clen)
        {
            prev_pos = byte_pos;
            continue;
        }
    
        if(count++ > max_chars)
            break;
                       
        prev_pos = byte_pos;
    }
    
    /* now backward to the first non-whitespace char */
    while(!isspace(s[byte_pos]))
        byte_pos--;
            
    return byte_pos;
}







/* Perl space */

MODULE = Search::Tools       PACKAGE = Search::Tools::UTF8

PROTOTYPES: enable

int
is_valid_utf8(string)
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
        U8 * pos;
        
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
        


MODULE = Search::Tools       PACKAGE = Search::Tools::Snipper

PROTOTYPES: enable

# return array of snippets
# TODO this is actually slower than pure perl!! is it the regex length?
AV*
_snip_xs(string, regex, max_chars, occur)
    SV* string;
    SV* regex;
    SV* max_chars;
    SV* occur;
    
  CODE:
    MAGIC      *mg              = NULL;
    REGEXP     *rx              = NULL;
    STRLEN      str_len;
    char       *str             = SvPV(string, str_len);
    char       *str_start       = str;
    char       *str_end         = str_start + str_len;
    int         maxc            = SvIV(max_chars);
    int         occ             = SvIV(occur);
    AV         *snips           = newAV();
    int         count           = 0;
    
    /* extract regexp struct from qr// entity */
    if (SvROK(regex)) 
    {
        SV *sv = SvRV(regex);
        if (SvMAGICAL(sv))
            mg = mg_find(sv, PERL_MAGIC_qr);
    }
    if (!mg)
        croak("not a qr// entity");
    rx = (REGEXP*)mg->mg_obj;
    
    if (!SvUTF8(string))
    {
        croak("%s is not flagged as a UTF-8 string", str);
    }

    while ( pregexec(rx, str, str_end, str, 1, string, 1) )
    {        
        int prev_i = prev_frag_index(str, rx->startp[0], maxc);
        int next_i = next_frag_index(str, rx->endp[0],   maxc);
        char *tmp  = str + prev_i;
        SV* snip = newSVpvn(tmp, next_i - prev_i);
  /*    char *match = savepvn(str + rx->startp[0], rx->endp[0] - rx->startp[0]);
        warn("match = %s\ncount = %d  prev_i = %d  next_i = %d  tmp = %s\n", 
              match, count, prev_i, next_i, SvPV(snip, PL_na));
  */      
        av_push(snips, snip);
        
        /* move pointer for next loop */
        str = str + next_i;
        
        if (++count > occ)
            break;
    }
    
    RETVAL = snips;
    
  OUTPUT:
    RETVAL
    