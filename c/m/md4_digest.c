/* Clean-room bounded MD4 implementation from RFC 1320's algorithm description. */
#include <stddef.h>
#include <stdint.h>

static uint32_t md4_rotl(uint32_t value, uint32_t shift)
{
    return (value << shift) | (value >> (32U - shift));
}

static uint32_t md4_f(uint32_t x, uint32_t y, uint32_t z)
{
    return (x & y) | (~x & z);
}

static uint32_t md4_g(uint32_t x, uint32_t y, uint32_t z)
{
    return (x & y) | (x & z) | (y & z);
}

static uint32_t md4_h(uint32_t x, uint32_t y, uint32_t z)
{
    return x ^ y ^ z;
}

static uint32_t md4_word(const int64_t *input, size_t message_length,
                         size_t padded_length, uint64_t bit_length,
                         size_t block_offset, size_t word_index)
{
    uint32_t word = 0;
    size_t first = block_offset + 4U * word_index;
    for (size_t byte = 0; byte < 4; ++byte) {
        size_t position = first + byte;
        uint32_t value = 0;
        if (position < message_length) {
            value = (uint32_t)input[position + 1U];
        } else if (position == message_length) {
            value = 0x80U;
        } else if (position >= padded_length - 8U) {
            value = (uint32_t)((bit_length >> (8U * (position - (padded_length - 8U)))) & 0xffU);
        }
        word |= value << (8U * (uint32_t)byte);
    }
    return word;
}

int64_t md4_digest(const int64_t *input, size_t input_length,
                   uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1U || input_length > 4098U) return -1;
    int64_t declared = input[0];
    if (declared < 0 || declared > 4096 || input_length != (size_t)declared + 1U) return -1;
    size_t message_length = (size_t)declared;
    for (size_t i = 0; i < message_length; ++i)
        if (input[i + 1U] < 0 || input[i + 1U] > 255) return -1;
    if (output == NULL || output_capacity < 16U) return -2;

    size_t padded_length = ((message_length + 8U) / 64U + 1U) * 64U;
    uint64_t bit_length = (uint64_t)message_length * 8U;
    uint32_t h0 = 0x67452301U, h1 = 0xefcdab89U;
    uint32_t h2 = 0x98badcfeU, h3 = 0x10325476U;
    static const uint32_t r1[4] = {3, 7, 11, 19};
    static const uint32_t r2[4] = {3, 5, 9, 13};
    static const uint32_t r3[4] = {3, 9, 11, 15};
    static const uint8_t order3[16] = {0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15};

    for (size_t offset = 0; offset < padded_length; offset += 64U) {
        uint32_t words[16];
        for (size_t i = 0; i < 16; ++i)
            words[i] = md4_word(input, message_length, padded_length, bit_length, offset, i);
        uint32_t a = h0, b = h1, c = h2, d = h3;
        for (uint32_t step = 0; step < 48; ++step) {
            uint32_t round = step / 16U, index = step % 16U;
            uint32_t f, k, shift, constant;
            if (round == 0U) {
                f = md4_f(b, c, d); k = index; shift = r1[index & 3U]; constant = 0;
            } else if (round == 1U) {
                f = md4_g(b, c, d); k = (index & 3U) * 4U + index / 4U;
                shift = r2[index & 3U]; constant = 0x5a827999U;
            } else {
                f = md4_h(b, c, d); k = order3[index];
                shift = r3[index & 3U]; constant = 0x6ed9eba1U;
            }
            uint32_t next_b = b + md4_rotl(a + f + words[k] + constant, shift);
            a = d; d = c; c = b; b = next_b;
        }
        h0 += a; h1 += b; h2 += c; h3 += d;
    }

    const uint32_t state[4] = {h0, h1, h2, h3};
    for (size_t word = 0; word < 4; ++word)
        for (size_t byte = 0; byte < 4; ++byte)
            output[word * 4U + byte] = (uint8_t)(state[word] >> (8U * (uint32_t)byte));
    return 16;
}
