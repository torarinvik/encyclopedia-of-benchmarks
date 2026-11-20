/* Clean-room bounded MD4 implementation from RFC 1320's algorithm description. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
uint32_t rotate_left(uint32_t value, uint32_t shift) {
    return (value << shift) | (value >> (32U - shift));
}
uint32_t choose(uint32_t x, uint32_t y, uint32_t z) { return (x & y) | (~x & z); }
uint32_t majority(uint32_t x, uint32_t y, uint32_t z) {
    return (x & y) | (x & z) | (y & z);
}
uint32_t parity(uint32_t x, uint32_t y, uint32_t z) { return x ^ y ^ z; }

uint32_t block_word(const int64_t *input, size_t n, size_t padded,
                    uint64_t bit_length, size_t offset, size_t index) {
    uint32_t result = 0;
    for (size_t j = 0; j < 4; ++j) {
        const size_t pos = offset + 4U * index + j;
        uint32_t byte = 0;
        if (pos < n) byte = static_cast<uint32_t>(input[pos + 1U]);
        else if (pos == n) byte = 0x80U;
        else if (pos >= padded - 8U)
            byte = static_cast<uint32_t>((bit_length >> (8U * (pos - (padded - 8U)))) & 255U);
        result |= byte << (8U * static_cast<uint32_t>(j));
    }
    return result;
}
}

extern "C" int64_t md4_digest(const int64_t *input, size_t input_length,
                               uint8_t *output, size_t output_capacity) {
    if (input == nullptr || input_length == 0 || input_length > 4098U) return -1;
    const int64_t count = input[0];
    if (count < 0 || count > 4096 || input_length != static_cast<size_t>(count) + 1U) return -1;
    const size_t n = static_cast<size_t>(count);
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1U] < 0 || input[i + 1U] > 255) return -1;
    if (output == nullptr || output_capacity < 16U) return -2;

    constexpr std::array<uint32_t, 4> shift1{3, 7, 11, 19};
    constexpr std::array<uint32_t, 4> shift2{3, 5, 9, 13};
    constexpr std::array<uint32_t, 4> shift3{3, 9, 11, 15};
    constexpr std::array<uint8_t, 16> order3{0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15};
    const size_t padded = ((n + 8U) / 64U + 1U) * 64U;
    const uint64_t bits = static_cast<uint64_t>(n) * 8U;
    uint32_t h0 = 0x67452301U, h1 = 0xefcdab89U, h2 = 0x98badcfeU, h3 = 0x10325476U;
    for (size_t offset = 0; offset < padded; offset += 64U) {
        std::array<uint32_t, 16> x{};
        for (size_t i = 0; i < x.size(); ++i) x[i] = block_word(input, n, padded, bits, offset, i);
        uint32_t a = h0, b = h1, c = h2, d = h3;
        for (uint32_t step = 0; step < 48; ++step) {
            const uint32_t round = step / 16U, j = step % 16U;
            uint32_t mix, word, shift, add;
            if (round == 0) {
                mix = choose(b, c, d); word = j; shift = shift1[j & 3U]; add = 0;
            } else if (round == 1) {
                mix = majority(b, c, d); word = (j & 3U) * 4U + j / 4U;
                shift = shift2[j & 3U]; add = 0x5a827999U;
            } else {
                mix = parity(b, c, d); word = order3[j]; shift = shift3[j & 3U]; add = 0x6ed9eba1U;
            }
            const uint32_t rotated = rotate_left(a + mix + x[word] + add, shift);
            const uint32_t old_d = d;
            d = c; c = b; b += rotated; a = old_d;
        }
        h0 += a; h1 += b; h2 += c; h3 += d;
    }
    const std::array<uint32_t, 4> digest{h0, h1, h2, h3};
    for (size_t i = 0; i < digest.size(); ++i)
        for (size_t j = 0; j < 4; ++j)
            output[4U * i + j] = static_cast<uint8_t>(digest[i] >> (8U * j));
    return 16;
}
