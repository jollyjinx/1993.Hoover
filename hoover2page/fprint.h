#ifndef FPRINT_H
#define FPRINT_H

/* This file provides procedures that construct fingerprints of
   strings of bytes via operations in GF[2^64].  GF[64] is represented
   as the set of polynomials of degree 64 with coefficients in Z(2),
   modulo an irreducible polynomial P of degree 64.  The computer
   internal representation is a 64 bit long word.

   Let g(S) be the string obtained from S by prepending the byte 0x80
   and appending eight 0x00 bytes.  Let f(S) be the polynomial
   associated to the string g(S) viewed as a polynomial with
   coefficients in the field Z(2). The fingerprint of S is simply the
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

typedef unsigned long fprint_t;

extern fprint_t fprint_empty;
/* The fingerprint of the empty string */

void fprint_init(void);
/* Should be called once to initiate the tables, before any other calls */

fprint_t fprint_fromstr (char *str);
/* Returns the fingerprint of str */

fprint_t fprint_extend (fprint_t t, char *addr, unsigned int len);
/* Returns the fingerprint of t concatenated with the len bytes
   beginning at address addr. To get the fingerprint of n bytes
   starting at s, use fprint_extend(fprint_empty, s, n) */

#define StringHash(str)		(fprint_fromstr(str))
 /* returns a 63-bit fingerprint for str; the msb is 0 */

#endif
