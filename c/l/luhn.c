#include <stddef.h>
#include <stdint.h>
#define MAX_DIGITS 64

/* Validate an even-length decimal digit array with the Luhn checksum. */
int64_t luhn_validate(const int64_t *input, size_t length) {
    if (!input || length < 1) return -1;
    int64_t n=input[0];
    if (n<2 || n>MAX_DIGITS || (n&1)!=0 || length!=(size_t)(n+1)) return -1;
    int64_t sum=0;
    for (int64_t i=0;i<n;i++) {
        int64_t digit=input[i+1];
        if (digit<0 || digit>9) return -1;
        if ((i&1)==0) { digit*=2; if (digit>9) digit-=9; }
        sum+=digit;
    }
    return sum%10==0 ? 1 : 0;
}
