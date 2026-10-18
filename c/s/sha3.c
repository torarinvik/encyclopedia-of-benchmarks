#include <stddef.h>
#include <stdint.h>

enum { MAX_MESSAGE_BYTES = 4096, MAX_PARSEABLE_INPUT_LENGTH = 4099, MAX_OUTPUT_BYTES = 64 };

static const uint64_t round_constants[24] = {
    UINT64_C(0x0000000000000001), UINT64_C(0x0000000000008082),
    UINT64_C(0x800000000000808a), UINT64_C(0x8000000080008000),
    UINT64_C(0x000000000000808b), UINT64_C(0x0000000080000001),
    UINT64_C(0x8000000080008081), UINT64_C(0x8000000000008009),
    UINT64_C(0x000000000000008a), UINT64_C(0x0000000000000088),
    UINT64_C(0x0000000080008009), UINT64_C(0x000000008000000a),
    UINT64_C(0x000000008000808b), UINT64_C(0x800000000000008b),
    UINT64_C(0x8000000000008089), UINT64_C(0x8000000000008003),
    UINT64_C(0x8000000000008002), UINT64_C(0x8000000000000080),
    UINT64_C(0x000000000000800a), UINT64_C(0x800000008000000a),
    UINT64_C(0x8000000080008081), UINT64_C(0x8000000000008080),
    UINT64_C(0x0000000080000001), UINT64_C(0x8000000080008008)
};

static const unsigned int rotation_offsets[25] = {
    0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43,
    25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14
};

static uint64_t rotate_left(uint64_t value, unsigned int amount)
{
    if (amount == 0) return value;
    return (value << amount) | (value >> (64 - amount));
}

static void keccak_f(uint64_t state[25])
{
    uint64_t column[5];
    uint64_t delta[5];
    uint64_t moved[25];
    for (size_t round = 0; round < 24; ++round) {
        for (size_t x = 0; x < 5; ++x)
            column[x] = state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20];
        for (size_t x = 0; x < 5; ++x)
            delta[x] = column[(x + 4) % 5] ^ rotate_left(column[(x + 1) % 5], 1);
        for (size_t y = 0; y < 5; ++y)
            for (size_t x = 0; x < 5; ++x)
                state[x + 5 * y] ^= delta[x];

        for (size_t y = 0; y < 5; ++y) {
            for (size_t x = 0; x < 5; ++x) {
                const size_t source = x + 5 * y;
                const size_t target_x = y;
                const size_t target_y = (2 * x + 3 * y) % 5;
                moved[target_x + 5 * target_y] = rotate_left(state[source], rotation_offsets[source]);
            }
        }

        for (size_t y = 0; y < 5; ++y)
            for (size_t x = 0; x < 5; ++x)
                state[x + 5 * y] = moved[x + 5 * y] ^
                    ((~moved[(x + 1) % 5 + 5 * y]) & moved[(x + 2) % 5 + 5 * y]);
        state[0] ^= round_constants[round];
    }
}

static void absorb_byte(uint64_t state[25], size_t offset, uint8_t value)
{
    state[offset / 8] ^= (uint64_t)value << ((offset % 8) * 8);
}

int64_t sha3(const int64_t *values, size_t length, uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (values[0] < 0 || values[0] > 3 || values[1] < 0 || values[1] > MAX_MESSAGE_BYTES) return -1;
    const size_t variant = (size_t)values[0];
    const size_t message_length = (size_t)values[1];
    if (length != 2 + message_length) return -1;
    for (size_t index = 0; index < message_length; ++index)
        if (values[2 + index] < 0 || values[2 + index] > 255) return -1;

    static const size_t digest_lengths[4] = {28, 32, 48, 64};
    static const size_t rates[4] = {144, 136, 104, 72};
    const size_t digest_length = digest_lengths[variant];
    const size_t rate = rates[variant];
    if (digest_length > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || output_capacity < digest_length) return -2;

    uint64_t state[25] = {0};
    size_t offset = 0;
    while (message_length - offset >= rate) {
        for (size_t index = 0; index < rate; ++index)
            absorb_byte(state, index, (uint8_t)values[2 + offset + index]);
        keccak_f(state);
        offset += rate;
    }

    uint8_t block[144] = {0};
    const size_t remaining = message_length - offset;
    for (size_t index = 0; index < remaining; ++index)
        block[index] = (uint8_t)values[2 + offset + index];
    block[remaining] ^= UINT8_C(0x06);
    block[rate - 1] ^= UINT8_C(0x80);
    for (size_t index = 0; index < rate; ++index) absorb_byte(state, index, block[index]);
    keccak_f(state);

    for (size_t index = 0; index < digest_length; ++index)
        output[index] = (uint8_t)(state[index / 8] >> ((index % 8) * 8));
    return (int64_t)digest_length;
}
