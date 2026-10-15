/* Compute an MD5 digest over a bounded byte array, using RFC 1321 padding. */
#include <stddef.h>
#include <stdint.h>

static const uint32_t MD5_SHIFTS[64] = {
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
};

static const uint32_t MD5_K[64] = {
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
    0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
    0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
    0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
    0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
    0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
    0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
    0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
    0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
    0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
    0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
    0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
    0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
    0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
};

static uint32_t md5_rotate_left(uint32_t value, uint32_t amount)
{
    return (value << amount) | (value >> (32U - amount));
}

static uint32_t md5_word(const int64_t *input, size_t length,
                         size_t padded_length, uint64_t bit_length,
                         size_t block_offset, size_t word_index)
{
    uint32_t word = 0;
    size_t start = block_offset + word_index * 4;
    for (size_t byte = 0; byte < 4; ++byte) {
        size_t position = start + byte;
        uint32_t value = 0;
        if (position < length) {
            value = (uint32_t)input[position];
        } else if (position == length) {
            value = 0x80U;
        } else if (position >= padded_length - 8) {
            value = (uint32_t)((bit_length >> (8U * (position - (padded_length - 8)))) & 0xffU);
        }
        word |= value << (8U * (uint32_t)byte);
    }
    return word;
}

int64_t md5(const int64_t *input, size_t length, uint8_t *output,
            size_t output_capacity)
{
    if (length > 4096 || (length != 0 && input == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < 0 || input[index] > 255) return -1;
    if (output == NULL || output_capacity < 16) return -2;

    size_t padded_length = ((length + 8) / 64 + 1) * 64;
    uint64_t bit_length = (uint64_t)length * 8U;
    uint32_t h0 = 0x67452301U, h1 = 0xefcdab89U;
    uint32_t h2 = 0x98badcfeU, h3 = 0x10325476U;

    for (size_t offset = 0; offset < padded_length; offset += 64) {
        uint32_t words[16];
        for (size_t index = 0; index < 16; ++index)
            words[index] = md5_word(input, length, padded_length, bit_length, offset, index);
        uint32_t a = h0, b = h1, c = h2, d = h3;
        for (uint32_t index = 0; index < 64; ++index) {
            uint32_t f, g;
            if (index < 16) {
                f = (b & c) | (~b & d);
                g = index;
            } else if (index < 32) {
                f = (d & b) | (~d & c);
                g = (5U * index + 1U) % 16U;
            } else if (index < 48) {
                f = b ^ c ^ d;
                g = (3U * index + 5U) % 16U;
            } else {
                f = c ^ (b | ~d);
                g = (7U * index) % 16U;
            }
            uint32_t sum = a + f + MD5_K[index] + words[g];
            uint32_t previous_d = d;
            d = c;
            c = b;
            b += md5_rotate_left(sum, MD5_SHIFTS[index]);
            a = previous_d;
        }
        h0 += a;
        h1 += b;
        h2 += c;
        h3 += d;
    }

    const uint32_t state[4] = {h0, h1, h2, h3};
    for (size_t word = 0; word < 4; ++word)
        for (size_t byte = 0; byte < 4; ++byte)
            output[word * 4 + byte] = (uint8_t)(state[word] >> (8U * (uint32_t)byte));
    return 16;
}
