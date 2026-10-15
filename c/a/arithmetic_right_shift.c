#include <stdint.h>

#define MAX_U53 UINT64_C(9007199254740991)
#define INVALID_RESULT INT64_C(-1)

int64_t arithmetic_right_shift(uint64_t n, uint64_t shift)
{
    if (n > MAX_U53 || shift > 53) return INVALID_RESULT;
    const unsigned count = (unsigned)shift;
    const uint64_t low_mask = (UINT64_C(1) << (53U - count)) - UINT64_C(1);
    const uint64_t fill_mask = (n >> 52) != 0 ? (MAX_U53 ^ low_mask) : UINT64_C(0);
    return (int64_t)(fill_mask | (n >> count));
}
