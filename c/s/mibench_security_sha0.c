#include <stddef.h>
#include <stdint.h>

enum { MAX_MESSAGE_BYTES = 55, OUTPUT_BYTES = 20 };

static uint32_t rol32(uint32_t value, unsigned shift) {
    return (value << shift) | (value >> (32u - shift));
}

static void transform_sha0(const uint8_t block[64], uint32_t state[5]) {
    uint32_t words[80];
    for (size_t i = 0; i < 16; ++i) {
        size_t p = i * 4;
        words[i] = ((uint32_t)block[p] << 24) | ((uint32_t)block[p + 1] << 16) |
                   ((uint32_t)block[p + 2] << 8) | block[p + 3];
    }
    for (size_t i = 16; i < 80; ++i)
        words[i] = words[i - 3] ^ words[i - 8] ^ words[i - 14] ^ words[i - 16];

    uint32_t a = state[0], b = state[1], c = state[2], d = state[3], e = state[4];
    for (size_t i = 0; i < 80; ++i) {
        uint32_t f, k;
        if (i < 20) { f = (b & c) | (~b & d); k = 0x5A827999u; }
        else if (i < 40) { f = b ^ c ^ d; k = 0x6ED9EBA1u; }
        else if (i < 60) { f = (b & c) | (b & d) | (c & d); k = 0x8F1BBCDCu; }
        else { f = b ^ c ^ d; k = 0xCA62C1D6u; }
        uint32_t temporary = rol32(a, 5) + f + e + words[i] + k;
        e = d; d = c; c = rol32(b, 30); b = a; a = temporary;
    }
    state[0] += a; state[1] += b; state[2] += c; state[3] += d; state[4] += e;
}

int64_t mibench_security_sha0(const int64_t *input, size_t input_length,
                              uint8_t *output, size_t output_capacity) {
    if (input == NULL || input_length < 1 || input_length > MAX_MESSAGE_BYTES + 2u) return -1;
    int64_t message_length = input[0];
    if (message_length < 0 || message_length > MAX_MESSAGE_BYTES ||
        input_length != (size_t)message_length + 1u) return -1;
    for (size_t i = 1; i < input_length; ++i)
        if (input[i] < 0 || input[i] > 255) return -1;

    uint8_t block[64] = {0};
    for (size_t i = 0; i < (size_t)message_length; ++i) block[i] = (uint8_t)input[i + 1];
    block[message_length] = 0x80;
    uint64_t bit_length = (uint64_t)message_length * 8u;
    for (size_t i = 0; i < 8; ++i) block[63u - i] = (uint8_t)(bit_length >> (8u * i));

    uint32_t state[5] = {0x67452301u, 0xEFCDAB89u, 0x98BADCFEu, 0x10325476u, 0xC3D2E1F0u};
    transform_sha0(block, state);
    if (output == NULL || output_capacity < OUTPUT_BYTES) return -2;
    for (size_t i = 0; i < 5; ++i)
        for (size_t j = 0; j < 4; ++j)
            output[i * 4 + j] = (uint8_t)(state[i] >> (24u - 8u * j));
    return OUTPUT_BYTES;
}
