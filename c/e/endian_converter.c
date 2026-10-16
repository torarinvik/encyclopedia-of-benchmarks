/* Reverse the byte order of a signed 32-bit integer. */
#include <stdint.h>
#define INVALID_RESULT (-INT64_C(2147483649))
int64_t endian_converter(int64_t value) {
    if (value < INT32_MIN || value > INT32_MAX) return INVALID_RESULT;
    uint32_t bits = (uint32_t)(int32_t)value;
    uint32_t reversed = ((bits & UINT32_C(0x000000ff)) << 24) |
                       ((bits & UINT32_C(0x0000ff00)) << 8)  |
                       ((bits & UINT32_C(0x00ff0000)) >> 8)  |
                       ((bits & UINT32_C(0xff000000)) >> 24);
    return reversed <= INT32_MAX ? (int64_t)reversed : (int64_t)reversed - INT64_C(4294967296);
}
