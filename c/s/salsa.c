#include <stddef.h>
#include <stdint.h>

static uint32_t rotate_left(uint32_t value, uint32_t amount) {
    return (value << amount) | (value >> (32U - amount));
}

static void quarter_round(uint32_t *state, size_t first, size_t second,
                          size_t third, size_t fourth) {
    state[second] ^= rotate_left(state[first] + state[fourth], 7);
    state[third] ^= rotate_left(state[second] + state[first], 9);
    state[fourth] ^= rotate_left(state[third] + state[second], 13);
    state[first] ^= rotate_left(state[fourth] + state[third], 18);
}

static void store_u32_le(uint8_t *output, size_t offset, uint32_t value) {
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(value >> (byte * 8));
}

// Reproduce the pinned 16-word Salsa core variant; this is not a stream cipher.
int64_t salsa(const int32_t *input, size_t length,
              uint8_t *output, size_t output_capacity) {
    if (input == NULL || length != 16) return -1;
    uint32_t original[16];
    for (size_t index = 0; index < 16; ++index) original[index] = (uint32_t)input[index];
    if (output == NULL || output_capacity < 64) return -2;

    uint32_t state[16];
    for (size_t index = 0; index < 16; ++index) state[index] = original[index];
    for (size_t round = 0; round < 10; ++round) {
        quarter_round(state, 0, 4, 8, 12);
        quarter_round(state, 5, 9, 13, 1);
        quarter_round(state, 10, 14, 2, 6);
        quarter_round(state, 15, 3, 7, 11);
        quarter_round(state, 0, 1, 2, 3);
        quarter_round(state, 5, 6, 7, 4);
        quarter_round(state, 10, 11, 8, 9);
        quarter_round(state, 15, 12, 13, 14);
    }
    for (size_t index = 0; index < 16; ++index) {
        state[index] += original[index];
        store_u32_le(output, index * 4, state[index]);
    }
    return 64;
}
