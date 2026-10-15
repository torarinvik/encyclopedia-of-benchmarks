/* XOR two values in the bounded unsigned 53-bit domain. */
#include <stdint.h>

#define MAX_UINT53 UINT64_C(9007199254740991)
#define INVALID_RESULT INT64_C(-1)

int64_t uint53_bitwise_xor(uint64_t n, uint64_t m)
{
    if (n > MAX_UINT53 || m > MAX_UINT53) return INVALID_RESULT;

    uint64_t result = 0;
    uint64_t bit = 1;
    while (n != 0 && m != 0) {
        uint64_t n_bit = n % 2;
        uint64_t m_bit = m % 2;
        result += ((n_bit + m_bit) % 2) * bit;
        n = (n - n_bit) / 2;
        m = (m - m_bit) / 2;
        bit *= 2;
    }
    return (int64_t)(result + (n + m) * bit);
}
