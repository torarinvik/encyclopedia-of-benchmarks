/* Sum base powers at the set-bit positions of n. */
#include <stdint.h>

int64_t frizzy_number(int64_t base, int64_t n)
{
    if (base < 2 || base > 10 || n < 0 || n > 1023) return -1;
    int64_t result = 0;
    int64_t power = 1;
    while (n > 0) {
        if (n % 2 == 1) result += power;
        n /= 2;
        if (n > 0) power *= base;
    }
    return result;
}
