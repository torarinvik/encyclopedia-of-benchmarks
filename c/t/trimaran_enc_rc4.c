/* ARC4 port from Trimaran/enc-rc4, Copyright (C) 2001-2003 Christophe Devine.
   Distributed under GPL-2.0-or-later; see the package license notice. */
#include <stddef.h>
#include <stdint.h>

#define VECTOR_COUNT 6
#define OUTPUT_BYTES 82
#define MAX_PASSES 2000

static const uint8_t keys[VECTOR_COUNT][8] = {
    {0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef},
    {0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef},
    {0},
    {0xef, 0x01, 0x23, 0x45},
    {0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef},
    {0xef, 0x01, 0x23, 0x45}
};
static const size_t key_lengths[VECTOR_COUNT] = {8, 8, 8, 4, 8, 4};
static const size_t data_lengths[VECTOR_COUNT] = {8, 8, 8, 20, 28, 10};
static const size_t output_offsets[VECTOR_COUNT] = {0, 8, 16, 24, 44, 72};
static const uint8_t plaintexts[VECTOR_COUNT][28] = {
    {0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef},
    {0},
    {0},
    {0},
    {0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0,
     0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0,
     0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0,
     0x12, 0x34, 0x56, 0x78},
    {0}
};

static void crypt_one(const uint8_t *key, size_t key_length, uint8_t *data, size_t length)
{
    int state[256];
    int x = 0, y = 0;
    for (int i = 0; i < 256; ++i) state[i] = i;
    int j = 0;
    for (int i = 0; i < 256; ++i) {
        j = (j + state[i] + key[i % key_length]) & 255;
        int temp = state[i]; state[i] = state[j]; state[j] = temp;
    }
    for (size_t offset = 0; offset < length; ++offset) {
        x = (x + 1) & 255;
        int a = state[x];
        y = (y + a) & 255;
        int b = state[y];
        state[x] = b; state[y] = a;
        data[offset] ^= (uint8_t)state[(a + b) & 255];
    }
}

int64_t trimaran_enc_rc4(const int64_t *input, size_t length,
                         uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length != 1 || input[0] < 1 || input[0] > MAX_PASSES) return -1;
    if (output == NULL || output_capacity < OUTPUT_BYTES) return -2;
    uint8_t staged[OUTPUT_BYTES];
    const size_t passes = (size_t)input[0];
    for (size_t vector = 0; vector < VECTOR_COUNT; ++vector) {
        const size_t offset = output_offsets[vector];
        for (size_t pass = 0; pass < passes; ++pass) {
            for (size_t byte = 0; byte < data_lengths[vector]; ++byte)
                staged[offset + byte] = plaintexts[vector][byte];
            crypt_one(keys[vector], key_lengths[vector], staged + offset, data_lengths[vector]);
        }
    }
    for (size_t byte = 0; byte < OUTPUT_BYTES; ++byte) output[byte] = staged[byte];
    return OUTPUT_BYTES;
}
