#include <stddef.h>
#include <stdint.h>

#define MAX_BYTES 64
#define MAX_PARSEABLE_INPUT_LENGTH 131
#define RATE_BYTES 136

static const uint64_t ROUND_CONSTANTS[24] = {
    UINT64_C(0x0000000000000001),
    UINT64_C(0x0000000000008082),
    UINT64_C(0x800000000000808a),
    UINT64_C(0x8000000080008000),
    UINT64_C(0x000000000000808b),
    UINT64_C(0x0000000080000001),
    UINT64_C(0x8000000080008081),
    UINT64_C(0x8000000000008009),
    UINT64_C(0x000000000000008a),
    UINT64_C(0x0000000000000088),
    UINT64_C(0x0000000080008009),
    UINT64_C(0x000000008000000a),
    UINT64_C(0x000000008000808b),
    UINT64_C(0x800000000000008b),
    UINT64_C(0x8000000000008089),
    UINT64_C(0x8000000000008003),
    UINT64_C(0x8000000000008002),
    UINT64_C(0x8000000000000080),
    UINT64_C(0x000000000000800a),
    UINT64_C(0x800000008000000a),
    UINT64_C(0x8000000080008081),
    UINT64_C(0x8000000000008080),
    UINT64_C(0x0000000080000001),
    UINT64_C(0x8000000080008008)
};
static const unsigned int ROTATION_OFFSETS[25] = {0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43, 25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14};

static uint64_t rotate_left(uint64_t value, unsigned int amount) {
    return amount == 0 ? value : (value << amount) | (value >> (64 - amount));
}

static void keccak_f1600(uint64_t state[25]) {
    uint64_t column[5], delta[5], moved[25];
    for (size_t round = 0; round < 24; ++round) {
        for (size_t x = 0; x < 5; ++x)
            column[x] = state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20];
        for (size_t x = 0; x < 5; ++x)
            delta[x] = column[(x + 4) % 5] ^ rotate_left(column[(x + 1) % 5], 1);
        for (size_t y = 0; y < 5; ++y) for (size_t x = 0; x < 5; ++x)
            moved[y + 5 * ((2 * x + 3 * y) % 5)] = rotate_left(state[x + 5 * y] ^ delta[x], ROTATION_OFFSETS[x + 5 * y]);
        for (size_t y = 0; y < 5; ++y) for (size_t x = 0; x < 5; ++x)
            state[x + 5 * y] = moved[x + 5 * y] ^ ((~moved[(x + 1) % 5 + 5 * y]) & moved[(x + 2) % 5 + 5 * y]);
        state[0] ^= ROUND_CONSTANTS[round];
    }
}

static void keccak256_bytes(const int64_t *input, size_t start, size_t byte_length, uint64_t digest[4]) {
    uint8_t block[RATE_BYTES] = {0};
    for (size_t i = 0; i < byte_length; ++i) block[i] = (uint8_t)input[start + i];
    block[byte_length] ^= 0x01;
    block[RATE_BYTES - 1] ^= 0x80;
    uint64_t state[25] = {0};
    for (size_t lane = 0; lane < RATE_BYTES / 8; ++lane)
        for (size_t byte = 0; byte < 8; ++byte)
            state[lane] |= (uint64_t)block[lane * 8 + byte] << (8 * byte);
    keccak_f1600(state);
    for (size_t lane = 0; lane < 4; ++lane) digest[lane] = state[lane];
}

int64_t string_hash_equality(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_BYTES || input[1] < 0 || input[1] > MAX_BYTES) return -1;
    size_t length_a = (size_t)input[0], length_b = (size_t)input[1];
    if (length != 2 + length_a + length_b) return -1;
    for (size_t i = 0; i < length_a + length_b; ++i)
        if (input[2 + i] < 0 || input[2 + i] > 255) return -1;
    uint64_t digest_a[4], digest_b[4];
    keccak256_bytes(input, 2, length_a, digest_a);
    keccak256_bytes(input, 2 + length_a, length_b, digest_b);
    for (size_t lane = 0; lane < 4; ++lane) if (digest_a[lane] != digest_b[lane]) return 0;
    return 1;
}
