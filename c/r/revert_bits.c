#include <stddef.h>
#include <stdint.h>

#define INPUT_COUNT 2
#define OUTPUT_BYTES 12

static uint32_t reverse_bits32(uint32_t n) {
    n = ((n >> 1) & UINT32_C(0x55555555)) | ((n & UINT32_C(0x55555555)) << 1);
    n = ((n >> 2) & UINT32_C(0x33333333)) | ((n & UINT32_C(0x33333333)) << 2);
    n = ((n >> 4) & UINT32_C(0x0f0f0f0f)) | ((n & UINT32_C(0x0f0f0f0f)) << 4);
    return ((n & UINT32_C(0xff000000)) >> 24) | ((n & UINT32_C(0x00ff0000)) >> 8) |
           ((n & UINT32_C(0x0000ff00)) << 8) | ((n & UINT32_C(0x000000ff)) << 24);
}

static uint64_t reverse_bits64(uint64_t n) {
    n = ((n >> 1) & UINT64_C(0x5555555555555555)) | ((n & UINT64_C(0x5555555555555555)) << 1);
    n = ((n >> 2) & UINT64_C(0x3333333333333333)) | ((n & UINT64_C(0x3333333333333333)) << 2);
    n = ((n >> 4) & UINT64_C(0x0f0f0f0f0f0f0f0f)) | ((n & UINT64_C(0x0f0f0f0f0f0f0f0f)) << 4);
    return ((n & UINT64_C(0xff00000000000000)) >> 56) |
           ((n & UINT64_C(0x00ff000000000000)) >> 40) |
           ((n & UINT64_C(0x0000ff0000000000)) >> 24) |
           ((n & UINT64_C(0x000000ff00000000)) >> 8) |
           ((n & UINT64_C(0x00000000ff000000)) << 8) |
           ((n & UINT64_C(0x0000000000ff0000)) << 24) |
           ((n & UINT64_C(0x000000000000ff00)) << 40) |
           ((n & UINT64_C(0x00000000000000ff)) << 56);
}

int64_t revert_bits(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != INPUT_COUNT || input[0] < 0 ||
        (uint64_t)input[0] > UINT32_MAX) return -1;
    if (output == NULL || capacity < OUTPUT_BYTES) return -2;

    const uint32_t reversed32 = reverse_bits32((uint32_t)input[0]);
    const uint64_t reversed64 = reverse_bits64((uint64_t)input[1]);
    for (size_t i = 0; i < 4; ++i) output[i] = (uint8_t)(reversed32 >> (8 * i));
    for (size_t i = 0; i < 8; ++i) output[4 + i] = (uint8_t)(reversed64 >> (8 * i));
    return OUTPUT_BYTES;
}
