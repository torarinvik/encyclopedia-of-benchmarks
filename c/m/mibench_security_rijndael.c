#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { RIJNDAEL_KEY_BYTES = 32, RIJNDAEL_BLOCK_BYTES = 16, RIJNDAEL_INPUT_BYTES = 48 };

static uint8_t rijndael_gf_mul(uint8_t left, uint8_t right)
{
    uint8_t result = 0;
    while (right != 0) {
        if (right & 1u) result ^= left;
        left = (uint8_t)((left << 1) ^ ((left & 0x80u) ? 0x1bu : 0u));
        right >>= 1;
    }
    return result;
}

static uint8_t rijndael_gf_pow(uint8_t value, unsigned exponent)
{
    uint8_t result = 1;
    while (exponent != 0) {
        if (exponent & 1u) result = rijndael_gf_mul(result, value);
        value = rijndael_gf_mul(value, value);
        exponent >>= 1;
    }
    return result;
}

static uint8_t rijndael_rotl8(uint8_t value, unsigned amount)
{
    return (uint8_t)((value << amount) | (value >> (8u - amount)));
}

static void rijndael_make_sbox(uint8_t sbox[256])
{
    for (unsigned value = 0; value < 256; ++value) {
        const uint8_t inverse = value == 0 ? 0 : rijndael_gf_pow((uint8_t)value, 254);
        sbox[value] = (uint8_t)(inverse ^ rijndael_rotl8(inverse, 1) ^
            rijndael_rotl8(inverse, 2) ^ rijndael_rotl8(inverse, 3) ^
            rijndael_rotl8(inverse, 4) ^ 0x63u);
    }
}

static void rijndael_encrypt_block(const uint8_t key[32], const uint8_t input[16], uint8_t output[16])
{
    uint8_t sbox[256], round_keys[240], state[16];
    static const uint8_t round_constants[7] = {1, 2, 4, 8, 16, 32, 64};
    rijndael_make_sbox(sbox);
    memcpy(round_keys, key, 32);
    size_t written = 32;
    while (written < sizeof round_keys) {
        const unsigned word = (unsigned)(written / 4);
        uint8_t temporary[4];
        for (unsigned j = 0; j < 4; ++j) temporary[j] = round_keys[written - 4 + j];
        if (word % 8 == 0) {
            const uint8_t first = temporary[0];
            temporary[0] = sbox[temporary[1]] ^ round_constants[word / 8 - 1];
            temporary[1] = sbox[temporary[2]];
            temporary[2] = sbox[temporary[3]];
            temporary[3] = sbox[first];
        } else if (word % 8 == 4) {
            for (unsigned j = 0; j < 4; ++j) temporary[j] = sbox[temporary[j]];
        }
        for (unsigned j = 0; j < 4; ++j) {
            round_keys[written] = round_keys[written - 32] ^ temporary[j];
            ++written;
        }
    }

    memcpy(state, input, 16);
    for (unsigned index = 0; index < 16; ++index) state[index] ^= round_keys[index];
    for (unsigned round = 1; round < 14; ++round) {
        for (unsigned index = 0; index < 16; ++index) state[index] = sbox[state[index]];
        uint8_t shifted[16];
        for (unsigned column = 0; column < 4; ++column)
            for (unsigned row = 0; row < 4; ++row)
                shifted[row + 4 * column] = state[row + 4 * ((column + row) % 4)];
        memcpy(state, shifted, 16);
        for (unsigned column = 0; column < 4; ++column) {
            const unsigned offset = 4 * column;
            const uint8_t a = state[offset], b = state[offset + 1];
            const uint8_t c = state[offset + 2], d = state[offset + 3];
            const uint8_t total = a ^ b ^ c ^ d;
            state[offset] = a ^ total ^ rijndael_gf_mul(a ^ b, 2);
            state[offset + 1] = b ^ total ^ rijndael_gf_mul(b ^ c, 2);
            state[offset + 2] = c ^ total ^ rijndael_gf_mul(c ^ d, 2);
            state[offset + 3] = d ^ total ^ rijndael_gf_mul(d ^ a, 2);
        }
        const unsigned key_offset = round * 16;
        for (unsigned index = 0; index < 16; ++index) state[index] ^= round_keys[key_offset + index];
    }
    for (unsigned index = 0; index < 16; ++index) state[index] = sbox[state[index]];
    uint8_t shifted[16];
    for (unsigned column = 0; column < 4; ++column)
        for (unsigned row = 0; row < 4; ++row)
            shifted[row + 4 * column] = state[row + 4 * ((column + row) % 4)];
    memcpy(state, shifted, 16);
    for (unsigned index = 0; index < 16; ++index) state[index] ^= round_keys[224 + index];
    memcpy(output, state, 16);
}

int64_t mibench_security_rijndael(const int64_t *values, size_t length,
                                  uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length != RIJNDAEL_INPUT_BYTES) return -1;
    for (size_t index = 0; index < RIJNDAEL_INPUT_BYTES; ++index)
        if (values[index] < 0 || values[index] > 255) return -1;
    if (output == NULL || output_capacity < RIJNDAEL_BLOCK_BYTES) return -2;
    uint8_t key[RIJNDAEL_KEY_BYTES], block[RIJNDAEL_BLOCK_BYTES], ciphertext[RIJNDAEL_BLOCK_BYTES];
    for (size_t index = 0; index < RIJNDAEL_KEY_BYTES; ++index) key[index] = (uint8_t)values[index];
    for (size_t index = 0; index < RIJNDAEL_BLOCK_BYTES; ++index)
        block[index] = (uint8_t)values[RIJNDAEL_KEY_BYTES + index];
    rijndael_encrypt_block(key, block, ciphertext);
    memcpy(output, ciphertext, RIJNDAEL_BLOCK_BYTES);
    return RIJNDAEL_BLOCK_BYTES;
}
