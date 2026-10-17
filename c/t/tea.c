#include <stddef.h>
#include <stdint.h>

#define TEA_DELTA UINT32_C(0x9e3779b9)
#define TEA_DECRYPT_SUM UINT32_C(0xc6ef3720)

static uint64_t combine_words(uint32_t low, uint32_t high) {
    return ((uint64_t)high << 32) | (uint64_t)low;
}

static uint64_t tea_encrypt(uint64_t block, uint64_t key0, uint64_t key1) {
    uint32_t b0 = (uint32_t)block;
    uint32_t b1 = (uint32_t)(block >> 32);
    const uint32_t k0 = (uint32_t)key0;
    const uint32_t k1 = (uint32_t)(key0 >> 32);
    const uint32_t k2 = (uint32_t)key1;
    const uint32_t k3 = (uint32_t)(key1 >> 32);
    uint32_t sum = 0;
    for (size_t round = 0; round < 32; ++round) {
        sum += TEA_DELTA;
        b0 += ((b1 << 4) + k0) ^ (b1 + sum) ^ ((b1 >> 5) + k1);
        b1 += ((b0 << 4) + k2) ^ (b0 + sum) ^ ((b0 >> 5) + k3);
    }
    return ((uint64_t)b1 << 32) | b0;
}

static uint64_t tea_decrypt(uint64_t block, uint64_t key0, uint64_t key1) {
    uint32_t b0 = (uint32_t)block;
    uint32_t b1 = (uint32_t)(block >> 32);
    const uint32_t k0 = (uint32_t)key0;
    const uint32_t k1 = (uint32_t)(key0 >> 32);
    const uint32_t k2 = (uint32_t)key1;
    const uint32_t k3 = (uint32_t)(key1 >> 32);
    uint32_t sum = TEA_DECRYPT_SUM;
    for (size_t round = 0; round < 32; ++round) {
        b1 -= ((b0 << 4) + k2) ^ (b0 + sum) ^ ((b0 >> 5) + k3);
        b0 -= ((b1 << 4) + k0) ^ (b1 + sum) ^ ((b1 >> 5) + k1);
        sum -= TEA_DELTA;
    }
    return ((uint64_t)b1 << 32) | b0;
}

static void store_u64_le(uint8_t *output, size_t offset, uint64_t value) {
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(value >> (byte * 8));
}

// Return ciphertext and the decrypted round-trip block as little-endian u64s.
int64_t tea(const int64_t *input, size_t length,
            uint8_t *output, size_t output_capacity) {
    if (input == NULL || length != 6) return -1;
    for (size_t index = 0; index < 6; ++index)
        if (input[index] < INT32_MIN || input[index] > INT32_MAX) return -1;
    if (output == NULL || output_capacity < 16) return -2;

    const uint64_t block = combine_words((uint32_t)(int32_t)input[0], (uint32_t)(int32_t)input[1]);
    const uint64_t key0 = combine_words((uint32_t)(int32_t)input[2], (uint32_t)(int32_t)input[3]);
    const uint64_t key1 = combine_words((uint32_t)(int32_t)input[4], (uint32_t)(int32_t)input[5]);
    const uint64_t ciphertext = tea_encrypt(block, key0, key1);
    const uint64_t recovered = tea_decrypt(ciphertext, key0, key1);
    store_u64_le(output, 0, ciphertext);
    store_u64_le(output, 8, recovered);
    return 16;
}
