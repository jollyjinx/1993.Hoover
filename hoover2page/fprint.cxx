#include <string.h>
#include "fprint.h"

/* This file provides procedures that construct fingerprints of
   strings of bytes via operations in GF[2^64].  GF[64] is represented
   as the set polynomials of degree 64 with coefficients in Z(2),
   modulo an irreducible polynomial P of degree 64.  The computer
   internal representation is a 64 bit long word.

   Let g(S) be the string obtained from S by prepending the byte 0x80
   and appending eight 0x00 bytes.  Let f(S) be the polynomial
   associated to the string g(S) viewed as a polynomial with
   coefficients in the field Z(2). The fingerprint of S simply the
   value f(S) modulo P.

   The irreducible polynomial pp used as a modulus is

              4    5    6    7    9    11    15    17    18    19
     1 + x + x  + x  + x  + x  + x  + x   + x   + x   + x   + x

        20    21    22    25    29    30    32    33    37    38
     + x   + x   + x   + x   + x   + x   + x   + x   + x   + x

        39    40    41    44    45    46    49    50    52    55
     + x   + x   + x   + x   + x   + x   + x   + x   + x   + x

        59    60    61    62    63
     + x   + x   + x   + x   + x

   fprint_pp is its representation.  However all computations are done
   modulo x*pp, and only the final result is computed modulo pp. The
   representation of x*pp is in fprint_p.  Notice that the coefficient
   of x^63 in all fingerprints will be 0. Thus all fingerprints viewed
   as integers will be even and their LSB can be used for other
   purposes.  */

const fprint_t
  fprint_zero = 0,
  fprint_one = 0x8000000000000000,
  fprint_x63 = 0x1,
  fprint_pp = 0xCF517E46C7CE691F;

fprint_t
  fprint_p,
  fprint_empty;  /* The fingerprint of the empty string */

/* These are the tables used for computing fingerprints.  Currently
   they are initiated in fprint_init but could be easily hardwired in
   the code.  */

fprint_t
  PowerTable[128],
  ByteModTable[8][256];

/**************************************************************************/
/* These routines initiate the tables.                                    */
/**************************************************************************/


void TimesX (fprint_t* ptr) {	/* This does *ptr := *ptr * x */
    short x63flag = (*ptr & fprint_x63);
    *ptr >>= 1;
    if (x63flag)  *ptr ^= fprint_p;
}

void fprint_init() {
    int i, j, k;
    fprint_t t;
    const unsigned char X7 = 1;
    /* Initialize constant polynomials */
    fprint_p = fprint_pp >> 1;
    fprint_empty = (fprint_p & fprint_x63) ? fprint_p ^ fprint_pp : fprint_p;
    /* Initialize tables */
    t = fprint_one;
    for (i=0; i <= 127; TimesX(&t),i++) {PowerTable[i] = t;}
    for (i=0; i<=7; i++) {
	for (j=0; j<=255; j++) {
	    ByteModTable[i][j] = fprint_zero;
	    for (k=0; k<=7; k++)
		if (j & (X7 << k)) ByteModTable[i][j] ^= PowerTable[127-i*8-k];
	}
    }
}


/**************************************************************************/
/* These routines actually compute the fingerprints                       */
/**************************************************************************/

static fprint_t ExtendByBytes(fprint_t init, uchar* source, uint n) {

/* Given init = the fingerprint of S, compute the fingerprint of S
   followed by n chars starting from source.  n must be a number
   between 0 and 7 */

    fprint_t temp = fprint_zero;
    fprint_t initCopy = init;
    uchar* ptr;
    int i;
    for (i=0, ptr = (uchar *) &initCopy;  i<n; i++, ptr++, source++) {
	temp ^= ByteModTable[i+8-n][*ptr ^ *source];
    }
    return (initCopy >> (8*n)) ^ temp;
}


static fprint_t ExtendByWords(fprint_t init, long unsigned *source,	uint n) {

/* Given init = the fingerprint of S, compute the fingerprint of S
   followed by n long unsigneds starting from source. */

    fprint_t temp, result;
    int i,j;
    unsigned char *ptr;
    if (!n) return init;
    result = init ^ source[0];
    for (i = 1; i < n; i++) {
	temp = source[i];
	for (j=0, ptr = (unsigned char *) &result;  j<=7; j++, ptr++) {
	    temp ^= ByteModTable[j][*ptr];
	}
	result = temp;
    }
    temp = fprint_zero;
    for (j=0, ptr = (unsigned char *) &result;  j<=7; j++, ptr++) {
	temp ^= ByteModTable[j][*ptr];
    }
    return temp;
}

fprint_t fprint_extend(fprint_t t, char *addr, uint len) {

/* Given that t is the fingerprint of a string s, compute the fingerprint
  of s followed by len chars starting at addr */
	
    uchar *p = (uchar *) addr;
    fprint_t result = t;
    uint residue;

    /* Do first residue bytes */
    if (len >= 8) {
	residue = 8 - (((unsigned long) p) & 7);
	if (residue != 8) {
	    result = ExtendByBytes(result, p, residue);
	    p += residue;
	    len -= residue;
	}
    }

    /* Do middle bytes, now starting from word boundary */
    if (len >= 8) {
	result = ExtendByWords (result, (long unsigned *) p, len/8);
	p += (len / 8) * 8;
	len %= 8;
    }

    /* Do last few bytes */
    if (len != 0) {result = ExtendByBytes (result, p, len);}
    if (result & fprint_x63) result ^= fprint_pp;
    return result;
}

fprint_t fprint_fromstr(char* str) {
    return (fprint_extend(fprint_empty, str, strlen (str)) >> 1L);
}
