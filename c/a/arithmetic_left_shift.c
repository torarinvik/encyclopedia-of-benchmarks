#include <stdint.h>

#define MAX_U53 UINT64_C(9007199254740991)
#define INVALID_RESULT INT64_C(-1)

int64_t arithmetic_left_shift(uint64_t n, uint64_t shift)
{
    if (n > MAX_U53 || shift > 53) return INVALID_RESULT;
    return (int64_t)((n << (unsigned)shift) & MAX_U53);
}
