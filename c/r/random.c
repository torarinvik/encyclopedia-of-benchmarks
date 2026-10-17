#include <stddef.h>
#include <stdint.h>

enum {
    MAX_COUNT = 256,
    MAX_INPUT_LENGTH = 5,
    MAX_OUTPUT_BYTES = MAX_COUNT * 4
};

static void write_u32_le(uint8_t *output, size_t index, uint32_t value) {
    const size_t offset = index * 4u;
    output[offset] = (uint8_t)value;
    output[offset + 1u] = (uint8_t)(value >> 8u);
    output[offset + 2u] = (uint8_t)(value >> 16u);
    output[offset + 3u] = (uint8_t)(value >> 24u);
}

static uint32_t rotate_right_u32(uint32_t value, uint32_t rotation) {
    const uint32_t left_shift = (32u - rotation) & 31u;
    return (value >> rotation) | (value << left_shift);
}

int64_t pcg32_random(const int64_t *values, size_t length,
                     uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 4u || length > MAX_INPUT_LENGTH) return -1;
    if (length != 4u) return -1;

    const uint64_t seed = (uint64_t)values[0];
    const uint64_t multiplier = (uint64_t)values[1];
    const int64_t stream_value = values[2];
    const int64_t count_value = values[3];
    if (stream_value < 0 || count_value < 0 || count_value > MAX_COUNT) return -1;

    const uint64_t increment = ((uint64_t)stream_value << 1u) | 1u;
    uint64_t state = seed + increment;
    state = state * multiplier + increment;
    const size_t count = (size_t)count_value;
    const size_t required_bytes = count * 4u;
    if (required_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || output_capacity < required_bytes) return -2;

    for (size_t index = 0; index < count; ++index) {
        uint64_t value = state;
        const uint32_t rotation = (uint32_t)(value >> 59u);
        state = state * multiplier + increment;
        value ^= value >> 18u;
        const uint32_t xorshifted = (uint32_t)(value >> 27u);
        write_u32_le(output, index, rotate_right_u32(xorshifted, rotation));
    }
    return (int64_t)required_bytes;
}
