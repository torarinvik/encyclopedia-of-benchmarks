/* Poly1305 using five 26-bit limbs; no constant-time guarantee is made. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_MESSAGE_LENGTH = 64, MAX_INPUT_LENGTH = 98 };
static const uint64_t LIMB_MASK = 0x3ffffffULL;

static uint32_t load32_le(const uint8_t *bytes)
{
    return (uint32_t)bytes[0] | ((uint32_t)bytes[1] << 8) |
           ((uint32_t)bytes[2] << 16) | ((uint32_t)bytes[3] << 24);
}

static void store32_le(uint8_t *bytes, uint32_t value)
{
    for (size_t i = 0; i < 4; ++i) bytes[i] = (uint8_t)(value >> (8 * i));
}

static void poly1305_tag(const uint8_t key[32], const uint8_t *message,
                         size_t message_length, uint8_t tag[16])
{
    uint64_t r0 = load32_le(key + 0) & 0x3ffffffULL;
    uint64_t r1 = (load32_le(key + 3) >> 2) & 0x3ffff03ULL;
    uint64_t r2 = (load32_le(key + 6) >> 4) & 0x3ffc0ffULL;
    uint64_t r3 = (load32_le(key + 9) >> 6) & 0x3f03fffULL;
    uint64_t r4 = (load32_le(key + 12) >> 8) & 0x00fffffULL;
    const uint64_t s1 = r1 * 5, s2 = r2 * 5, s3 = r3 * 5, s4 = r4 * 5;
    uint64_t h0 = 0, h1 = 0, h2 = 0, h3 = 0, h4 = 0;
    size_t offset = 0;
    while (offset < message_length) {
        uint8_t block[16] = {0};
        size_t block_length = message_length - offset;
        if (block_length > 16) block_length = 16;
        for (size_t i = 0; i < block_length; ++i) block[i] = message[offset + i];
        uint64_t high_bit = 1ULL << 24;
        if (block_length < 16) { block[block_length] = 1; high_bit = 0; }
        h0 += load32_le(block + 0) & LIMB_MASK;
        h1 += (load32_le(block + 3) >> 2) & LIMB_MASK;
        h2 += (load32_le(block + 6) >> 4) & LIMB_MASK;
        h3 += (load32_le(block + 9) >> 6) & LIMB_MASK;
        h4 += (load32_le(block + 12) >> 8) | high_bit;

        const uint64_t d0 = h0 * r0 + h1 * s4 + h2 * s3 + h3 * s2 + h4 * s1;
        const uint64_t d1 = h0 * r1 + h1 * r0 + h2 * s4 + h3 * s3 + h4 * s2;
        const uint64_t d2 = h0 * r2 + h1 * r1 + h2 * r0 + h3 * s4 + h4 * s3;
        const uint64_t d3 = h0 * r3 + h1 * r2 + h2 * r1 + h3 * r0 + h4 * s4;
        const uint64_t d4 = h0 * r4 + h1 * r3 + h2 * r2 + h3 * r1 + h4 * r0;
        uint64_t carry = d0 >> 26; h0 = d0 & LIMB_MASK;
        uint64_t q1 = d1 + carry; carry = q1 >> 26; h1 = q1 & LIMB_MASK;
        uint64_t q2 = d2 + carry; carry = q2 >> 26; h2 = q2 & LIMB_MASK;
        uint64_t q3 = d3 + carry; carry = q3 >> 26; h3 = q3 & LIMB_MASK;
        uint64_t q4 = d4 + carry; carry = q4 >> 26; h4 = q4 & LIMB_MASK;
        h0 += carry * 5;
        carry = h0 >> 26; h0 &= LIMB_MASK; h1 += carry;
        offset += block_length;
    }

    for (size_t pass = 0; pass < 3; ++pass) {
        uint64_t carry = h0 >> 26; h0 &= LIMB_MASK; h1 += carry;
        carry = h1 >> 26; h1 &= LIMB_MASK; h2 += carry;
        carry = h2 >> 26; h2 &= LIMB_MASK; h3 += carry;
        carry = h3 >> 26; h3 &= LIMB_MASK; h4 += carry;
        carry = h4 >> 26; h4 &= LIMB_MASK; h0 += carry * 5;
        carry = h0 >> 26; h0 &= LIMB_MASK; h1 += carry;
    }
    if (h4 == LIMB_MASK && h3 == LIMB_MASK && h2 == LIMB_MASK &&
        h1 == LIMB_MASK && h0 >= LIMB_MASK - 4) {
        h0 -= LIMB_MASK - 4;
        h1 = h2 = h3 = h4 = 0;
    }

    uint64_t f0 = ((h0 | (h1 << 26)) & 0xffffffffULL) + load32_le(key + 16);
    uint64_t f1 = ((h1 >> 6 | (h2 << 20)) & 0xffffffffULL) + load32_le(key + 20) + (f0 >> 32);
    uint64_t f2 = ((h2 >> 12 | (h3 << 14)) & 0xffffffffULL) + load32_le(key + 24) + (f1 >> 32);
    uint64_t f3 = ((h3 >> 18 | (h4 << 8)) & 0xffffffffULL) + load32_le(key + 28) + (f2 >> 32);
    store32_le(tag + 0, (uint32_t)f0);
    store32_le(tag + 4, (uint32_t)f1);
    store32_le(tag + 8, (uint32_t)f2);
    store32_le(tag + 12, (uint32_t)f3);
}

int64_t poly1305(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 33 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_length = input[0];
    if (raw_length < 0 || raw_length > MAX_MESSAGE_LENGTH || length != 33 + (size_t)raw_length) return -1;
    for (size_t i = 1; i < length; ++i) if (input[i] < 0 || input[i] > 255) return -1;
    if (output == NULL || output_capacity < 16) return -2;
    uint8_t key[32], message[MAX_MESSAGE_LENGTH], tag[16];
    for (size_t i = 0; i < 32; ++i) key[i] = (uint8_t)input[1 + i];
    for (size_t i = 0; i < (size_t)raw_length; ++i) message[i] = (uint8_t)input[33 + i];
    poly1305_tag(key, message, (size_t)raw_length, tag);
    for (size_t i = 0; i < 16; ++i) output[i] = tag[i];
    return 16;
}
