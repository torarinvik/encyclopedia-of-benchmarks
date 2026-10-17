#include <stddef.h>
#include <stdint.h>

static const uint8_t p8[8] = {6, 3, 7, 4, 8, 5, 10, 9};
static const uint8_t p10[10] = {3, 5, 2, 7, 4, 10, 1, 9, 8, 6};
static const uint8_t p4[4] = {2, 4, 3, 1};
static const uint8_t ip[8] = {2, 6, 3, 1, 4, 8, 5, 7};
static const uint8_t ip_inverse[8] = {4, 1, 3, 5, 7, 2, 8, 6};
static const uint8_t expansion[8] = {4, 1, 2, 3, 2, 3, 4, 1};
static const uint8_t sboxes[2][4][4] = {
    {{1, 0, 3, 2}, {3, 2, 1, 0}, {0, 2, 1, 3}, {3, 1, 3, 2}},
    {{0, 1, 2, 3}, {2, 0, 1, 3}, {3, 0, 1, 0}, {2, 1, 0, 3}}
};

static uint32_t table_value(uint32_t table, size_t index) {
    switch (table) {
        case 0: return p8[index];
        case 1: return p10[index];
        case 2: return ip[index];
        case 3: return ip_inverse[index];
        case 4: return expansion[index];
        default: return p4[index];
    }
}

static uint32_t permute(uint32_t value, uint32_t input_bits,
                        uint32_t table, size_t count) {
    uint32_t result = 0;
    for (size_t index = 0; index < count; ++index) {
        const uint32_t position = table_value(table, index);
        result = (result << 1) | ((value >> (input_bits - position)) & 1U);
    }
    return result;
}

static uint32_t rotate5(uint32_t value, uint32_t amount) {
    return ((value << amount) | (value >> (5U - amount))) & 31U;
}

static uint32_t subkey(uint32_t key, uint32_t round) {
    const uint32_t selected = permute(key, 10, 1, 10);
    uint32_t left = selected >> 5;
    uint32_t right = selected & 31U;
    left = rotate5(left, 1);
    right = rotate5(right, 1);
    if (round != 0) {
        left = rotate5(left, 2);
        right = rotate5(right, 2);
    }
    return permute((left << 5) | right, 10, 0, 8);
}

static uint32_t sbox_value(uint32_t box, uint32_t nibble) {
    const uint32_t row = ((nibble & 8U) >> 2) | (nibble & 1U);
    const uint32_t column = (nibble >> 1) & 3U;
    return sboxes[box][row][column];
}

static uint32_t fk(uint32_t state, uint32_t key) {
    const uint32_t left = state >> 4;
    const uint32_t right = state & 15U;
    const uint32_t mixed = permute(right, 4, 4, 8) ^ key;
    const uint32_t substituted = (sbox_value(0, mixed >> 4) << 2) |
                                 sbox_value(1, mixed & 15U);
    return ((left ^ permute(substituted, 4, 5, 4)) << 4) | right;
}

static uint32_t crypt(uint32_t message, uint32_t key, int decrypt) {
    const uint32_t first = subkey(key, 0);
    const uint32_t second = subkey(key, 1);
    uint32_t state = permute(message, 8, 2, 8);
    state = fk(state, decrypt ? second : first);
    state = ((state & 15U) << 4) | (state >> 4);
    state = fk(state, decrypt ? first : second);
    return permute(state, 8, 3, 8);
}

// Return ciphertext and the plaintext recovered with the reversed subkeys.
int64_t sdes(const int64_t *input, size_t length,
             uint8_t *output, size_t output_capacity) {
    if (input == NULL || length != 2) return -1;
    if (input[0] < 0 || input[0] > 1023 || input[1] < 0 || input[1] > 255) return -1;
    if (output == NULL || output_capacity < 2) return -2;
    const uint32_t ciphertext = crypt((uint32_t)input[1], (uint32_t)input[0], 0);
    const uint32_t recovered = crypt(ciphertext, (uint32_t)input[0], 1);
    output[0] = (uint8_t)ciphertext;
    output[1] = (uint8_t)recovered;
    return 2;
}
