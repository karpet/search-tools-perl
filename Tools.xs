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

static void
safe_av_push_av(AV* av, I32 index, SV* value)
{
    SV** ref = av_fetch(av, index, 1);
    if (ref == NULL)
    {
        croak("bad av_fetch of arrayref in array index %d", index);
    }
    av_push((AV*)SvRV(*ref), value);
}


/* Perl space */

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
    
# this is only 0.001sec faster than its pure Perl version!!
# and that without the isHTML check!!!
int
_re_match_xs(text, regex, snips, ranges, Nchar, max_snips, isHTML)
    SV  *text;
    SV  *regex;
    AV  *snips;
    AV  *ranges;
    SV  *Nchar;
    SV  *max_snips;
    SV  *isHTML;
    
  CODE:
    MAGIC      *mg              = NULL;
    REGEXP     *rx              = NULL;
    STRLEN      str_len;
    char       *str             = SvPV(text, str_len);
    char       *str_start       = str;
    char       *str_end         = str_start + str_len;
    int         maxc            = SvIV(Nchar);
    int         occur           = SvIV(max_snips);
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
    
    if (!SvUTF8(text))
    {
        croak("%s is not flagged as a UTF-8 string", str);
    }
    
    while ( pregexec(rx, str, str_end, str, 1, text, 1) )
    {   
#if (PERL_VERSION >= 9) && (PERL_SUBVERSION >= 5)
        I32 start   = rx->offs[2].start;
        I32 end     = rx->offs[2].end;
#else 
        I32 start   = rx->startp[2];
        I32 end     = rx->endp[2];
#endif

        int match_len   = end - start;
        int prev_i      = prev_frag_index(str, start, maxc);
        int next_i      = next_frag_index(str, end,   maxc);

        /* TODO this logic needs work -- still overlapping */
        if(av_exists(ranges, prev_i))
        {
            warn("seen start pos %d before in ranges", prev_i);
            str = str + end;
            continue;
        }
            
        char *tmp  = str + prev_i;
        /* count++;      perl increments here before range fill */
        SV* snip = newSVpvn(tmp, next_i - prev_i);
        SvUTF8_on(snip);

        char *match = savepvn(str + start, match_len);
        warn("match = '%s'\ncount = %d  prev_i = %d  next_i = %d  tmp = %s\n", 
              match, count, prev_i, next_i, SvPV(snip, PL_na));

        
        /* move pointer for next loop */
        str = str + next_i;

        /* fill out ranges for each byte in tmp */
        int i;
        for (i=prev_i; i <= next_i; i++)
        {
            if(av_store(ranges, i, newSViv(1)) == NULL)
            {
                croak("fatal error creating range byte %d", i);
            }
        }
        
        /* TODO isHTML fix to try and catch broken tagsets 
           -- do it in *_frag_index() */
        
        safe_av_push_av(snips, 0, snip);
        safe_av_push_av(snips, 1, newSViv(prev_i));
        
        if (++count >= occur)
            break;
    }
    
    RETVAL = count;

  OUTPUT:
    RETVAL