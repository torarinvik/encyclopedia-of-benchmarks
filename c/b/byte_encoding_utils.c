/* Reverse the eight bytes in a 64-bit bit pattern. */
#include <stdint.h>

int64_t byte_encoding_utils(int64_t value) {
    const uint64_t bits = (uint64_t)value;
    const uint64_t reversed = ((bits & UINT64_C(0x00000000000000ff)) << 56) |
                              ((bits & UINT64_C(0x000000000000ff00)) << 40) |
                              ((bits & UINT64_C(0x0000000000ff0000)) << 24) |
                              ((bits & UINT64_C(0x00000000ff000000)) << 8)  |
                              ((bits & UINT64_C(0x000000ff00000000)) >> 8)  |
                              ((bits & UINT64_C(0x0000ff0000000000)) >> 24) |
                              ((bits & UINT64_C(0x00ff000000000000)) >> 40) |
                              ((bits & UINT64_C(0xff00000000000000)) >> 56);
    if (reversed <= (uint64_t)INT64_MAX) return (int64_t)reversed;
    return -1 - (int64_t)(UINT64_MAX - reversed);
}
