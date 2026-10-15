/* Bitwise AND of two nonnegative integers exactly representable by Lua numbers. */
#include <stdint.h>

#define MAX_UINT53 INT64_C(9007199254740991)

int64_t uint53_bitwise_and(int64_t n, int64_t m)
{
    if (n < 0 || m < 0 || n > MAX_UINT53 || m > MAX_UINT53) return -1;
    int64_t result = 0;
    int64_t bit = 1;
    while (n != 0 && m != 0) {
        const int64_t n_bit = n % 2;
        const int64_t m_bit = m % 2;
        result += n_bit * m_bit * bit;
        n = (n - n_bit) / 2;
        m = (m - m_bit) / 2;
        bit *= 2;
    }
    return result;
}
