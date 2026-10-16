/* Damm validation and check-digit calculation over decimal digit arrays. */
#include <stddef.h>
#include <stdint.h>
#define MAX_DIGITS 256
static const int8_t TABLE[100] = {0, 3, 1, 7, 5, 9, 8, 6, 4, 2, 7, 0, 9, 2, 1, 5, 4, 8, 6, 3, 4, 2, 0, 6, 8, 7, 1, 3, 5, 9, 1, 7, 5, 0, 9, 8, 3, 4, 2, 6, 6, 1, 2, 3, 0, 4, 5, 9, 7, 8, 3, 6, 7, 4, 2, 0, 9, 5, 8, 1, 5, 8, 6, 9, 7, 2, 0, 1, 3, 4, 8, 9, 4, 5, 3, 6, 2, 0, 1, 7, 9, 4, 3, 8, 6, 1, 7, 2, 0, 5, 2, 5, 8, 1, 4, 3, 6, 7, 9, 0};
int64_t damm(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_DIGITS + 2) return -1;
    int64_t mode=input[0], n=input[1];
    if ((mode != 0 && mode != 1) || n < 1 || n > MAX_DIGITS || length != (size_t)n + 2) return -1;
    int state=0;
    for(size_t i=0;i<(size_t)n;i++) { int64_t d=input[i+2]; if(d<0||d>9)return -1; state=TABLE[state*10+(int)d]; }
    return mode==0 ? (state==0 ? 1 : 0) : state;
}
