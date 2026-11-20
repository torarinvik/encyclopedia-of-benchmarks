#include <stddef.h>
#include <stdint.h>

enum {
    STATE_SIZE = 55,
    SHORT_LAG = 24,
    WARMUP_VALUES = 165,
    MAX_COUNT = 64
};
static const int32_t MODULUS = INT32_C(1000000000);

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t subtractive_prng_bentley_seeded_sequence(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 2) return -1;
    const int64_t seed = input[0], count = input[1];
    if (seed < 0 || seed >= MODULUS || count < 0 || count > MAX_COUNT) return -1;
    const size_t required = (size_t)count * 8;
    if (capacity < required || (required != 0 && output == NULL)) return -2;
    if (count == 0) return 0;

    int32_t seed_state[STATE_SIZE];
    int32_t ring[STATE_SIZE];
    seed_state[0] = (int32_t)seed;
    seed_state[1] = 1;
    for (size_t i = 2; i < STATE_SIZE; ++i) {
        int32_t value = seed_state[i - 2] - seed_state[i - 1];
        if (value < 0) value += MODULUS;
        seed_state[i] = value;
    }
    for (size_t i = 0; i < STATE_SIZE; ++i)
        ring[i] = seed_state[(34 * (i + 1)) % STATE_SIZE];

    size_t write_index = 0;
    size_t lag_index = STATE_SIZE - SHORT_LAG;
    for (size_t step = 0; step < WARMUP_VALUES + (size_t)count; ++step) {
        int32_t value = ring[write_index] - ring[lag_index];
        if (value < 0) value += MODULUS;
        ring[write_index] = value;
        if (step >= WARMUP_VALUES)
            put_i64_le(output, (step - WARMUP_VALUES) * 8, value);
        write_index = (write_index + 1) % STATE_SIZE;
        lag_index = (lag_index + 1) % STATE_SIZE;
    }
    return (int64_t)required;
}
