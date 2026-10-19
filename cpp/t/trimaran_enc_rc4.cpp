/* ARC4 port from Trimaran/enc-rc4, Copyright (C) 2001-2003 Christophe Devine.
   Distributed under GPL-2.0-or-later; see the package license notice. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t vector_count = 6, output_bytes = 82, max_passes = 2000;
constexpr std::uint8_t keys[vector_count][8] = {
    {0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef}, {0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef},
    {0}, {0xef,0x01,0x23,0x45}, {0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef}, {0xef,0x01,0x23,0x45}
};
constexpr std::size_t key_lengths[vector_count] = {8,8,8,4,8,4};
constexpr std::size_t data_lengths[vector_count] = {8,8,8,20,28,10};
constexpr std::size_t output_offsets[vector_count] = {0,8,16,24,44,72};
constexpr std::uint8_t plaintexts[vector_count][28] = {
    {0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef}, {0}, {0}, {0},
    {0x12,0x34,0x56,0x78,0x9a,0xbc,0xde,0xf0,0x12,0x34,0x56,0x78,0x9a,0xbc,0xde,0xf0,
     0x12,0x34,0x56,0x78,0x9a,0xbc,0xde,0xf0,0x12,0x34,0x56,0x78}, {0}
};
void crypt_one(const std::uint8_t *key, std::size_t key_length, std::uint8_t *data, std::size_t length) {
    int state[256], x = 0, y = 0;
    for (int i = 0; i < 256; ++i) state[i] = i;
    int j = 0;
    for (int i = 0; i < 256; ++i) {
        j = (j + state[i] + key[i % key_length]) & 255;
        const int temp = state[i]; state[i] = state[j]; state[j] = temp;
    }
    for (std::size_t offset = 0; offset < length; ++offset) {
        x = (x + 1) & 255;
        const int a = state[x]; y = (y + a) & 255;
        const int b = state[y]; state[x] = b; state[y] = a;
        data[offset] ^= static_cast<std::uint8_t>(state[(a + b) & 255]);
    }
}
}

extern "C" std::int64_t trimaran_enc_rc4(const std::int64_t *input, std::size_t length,
                                           std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length != 1 || input[0] < 1 || input[0] > static_cast<std::int64_t>(max_passes)) return -1;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    std::uint8_t staged[output_bytes];
    for (std::size_t vector = 0; vector < vector_count; ++vector) {
        const std::size_t offset = output_offsets[vector];
        for (std::size_t pass = 0; pass < static_cast<std::size_t>(input[0]); ++pass) {
            for (std::size_t byte = 0; byte < data_lengths[vector]; ++byte) staged[offset + byte] = plaintexts[vector][byte];
            crypt_one(keys[vector], key_lengths[vector], staged + offset, data_lengths[vector]);
        }
    }
    for (std::size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(output_bytes);
}
