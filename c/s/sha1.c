#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT 4096
#define MAX_PADDED 4160

static uint32_t rol(uint32_t value, unsigned shift)
{
    return (value << shift) | (value >> (32 - shift));
}

int64_t sha1(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (length > MAX_INPUT || (length > 0 && input == NULL)) return -1;
    for (size_t i = 0; i < length; ++i)
        if (input[i] < 0 || input[i] > 255) return -1;

    uint8_t padded[MAX_PADDED] = {0};
    for (size_t i = 0; i < length; ++i) padded[i] = (uint8_t)input[i];
    padded[length] = 0x80;
    const size_t blocks = (length + 9 + 63) / 64;
    const size_t padded_length = blocks * 64;
    const uint64_t bit_length = (uint64_t)length * 8;
    for (size_t i = 0; i < 8; ++i)
        padded[padded_length - 1 - i] = (uint8_t)(bit_length >> (8 * i));

    uint32_t h0 = 0x67452301, h1 = 0xEFCDAB89, h2 = 0x98BADCFE;
    uint32_t h3 = 0x10325476, h4 = 0xC3D2E1F0;
    for (size_t block = 0; block < blocks; ++block) {
        uint32_t w[80];
        for (size_t i = 0; i < 16; ++i) {
            const size_t p = block * 64 + i * 4;
            w[i] = ((uint32_t)padded[p] << 24) | ((uint32_t)padded[p+1] << 16) |
                   ((uint32_t)padded[p+2] << 8) | padded[p+3];
        }
        for (size_t i = 16; i < 80; ++i) w[i] = rol(w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16], 1);
        uint32_t a = h0, b = h1, c = h2, d = h3, e = h4;
        for (size_t i = 0; i < 80; ++i) {
            uint32_t f, k;
            if (i < 20) { f = (b & c) | ((~b) & d); k = 0x5A827999; }
            else if (i < 40) { f = b ^ c ^ d; k = 0x6ED9EBA1; }
            else if (i < 60) { f = (b & c) | (b & d) | (c & d); k = 0x8F1BBCDC; }
            else { f = b ^ c ^ d; k = 0xCA62C1D6; }
            const uint32_t temp = rol(a, 5) + f + e + k + w[i];
            e = d; d = c; c = rol(b, 30); b = a; a = temp;
        }
        h0 += a; h1 += b; h2 += c; h3 += d; h4 += e;
    }
    if (output == NULL || capacity < 20) return -2;
    const uint32_t digest[5] = {h0, h1, h2, h3, h4};
    for (size_t i = 0; i < 5; ++i)
        for (size_t byte = 0; byte < 4; ++byte)
            output[i*4+byte] = (uint8_t)(digest[i] >> (24 - 8*byte));
    return 20;
}
