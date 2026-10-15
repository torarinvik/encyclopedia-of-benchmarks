#include <stdint.h>

#define MAX_NUM UINT64_C(2147483647)
#define INVALID_RESULT INT64_C(-1)

int64_t find_nth_bit(uint64_t num, uint64_t n)
{
    if (num > MAX_NUM || n < 1 || n > 31) return INVALID_RESULT;
    const int32_t value = (int32_t)num;
    const int32_t shift = (int32_t)(n - 1);
    return (value & (INT32_C(1) << shift)) >> shift;
}
