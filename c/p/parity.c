/* Return the parity of the set-bit count using Kernighan's bit clearing. */
#include <stdint.h>

int64_t parity(int64_t number)
{
    if (number < 0) return -1;
    int64_t result = 0;
    while (number != 0) {
        result ^= 1;
        number &= number - 1;
    }
    return result;
}
