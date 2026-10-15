/* Count set bits in the bounded unsigned 53-bit domain, byte by byte. */
#include <stdint.h>

#define MAX_UINT53 INT64_C(9007199254740991)

static int64_t count_byte_ones(int64_t byte)
{
    int64_t ones = 0;
    while (byte > 0) {
        int64_t bit = byte % 2;
        ones += bit;
        byte = (byte - bit) / 2;
    }
    return ones;
}

int64_t uint53_ones_count(int64_t n)
{
    if (n < 0 || n > MAX_UINT53) return -1;

    int64_t ones = 0;
    while (n != 0) {
        int64_t byte = n % 256;
        ones += count_byte_ones(byte);
        n = (n - byte) / 256;
    }
    return ones;
}
