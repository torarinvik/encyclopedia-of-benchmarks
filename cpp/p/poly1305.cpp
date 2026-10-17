/* Poly1305 using five 26-bit limbs; no constant-time guarantee is made. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_message_length = 64;
constexpr std::size_t max_input_length = 98;
constexpr std::uint64_t limb_mask = 0x3ffffffULL;

std::uint32_t load32_le(const std::uint8_t *bytes) noexcept
{
    return static_cast<std::uint32_t>(bytes[0]) |
           (static_cast<std::uint32_t>(bytes[1]) << 8) |
           (static_cast<std::uint32_t>(bytes[2]) << 16) |
           (static_cast<std::uint32_t>(bytes[3]) << 24);
}

void store32_le(std::uint8_t *bytes, std::uint32_t value) noexcept
{
    for (std::size_t i = 0; i < 4; ++i) bytes[i] = static_cast<std::uint8_t>(value >> (8 * i));
}

void poly1305_tag(const std::uint8_t key[32], const std::uint8_t *message,
                  std::size_t message_length, std::uint8_t tag[16]) noexcept
{
    std::uint64_t r0 = load32_le(key + 0) & 0x3ffffffULL;
    std::uint64_t r1 = (load32_le(key + 3) >> 2) & 0x3ffff03ULL;
    std::uint64_t r2 = (load32_le(key + 6) >> 4) & 0x3ffc0ffULL;
    std::uint64_t r3 = (load32_le(key + 9) >> 6) & 0x3f03fffULL;
    std::uint64_t r4 = (load32_le(key + 12) >> 8) & 0x00fffffULL;
    const std::uint64_t s1 = r1 * 5, s2 = r2 * 5, s3 = r3 * 5, s4 = r4 * 5;
    std::uint64_t h0 = 0, h1 = 0, h2 = 0, h3 = 0, h4 = 0;
    std::size_t offset = 0;
    while (offset < message_length) {
        std::uint8_t block[16]{};
        auto block_length = message_length - offset;
        if (block_length > 16) block_length = 16;
        for (std::size_t i = 0; i < block_length; ++i) block[i] = message[offset + i];
        std::uint64_t high_bit = 1ULL << 24;
        if (block_length < 16) { block[block_length] = 1; high_bit = 0; }
        h0 += load32_le(block + 0) & limb_mask;
        h1 += (load32_le(block + 3) >> 2) & limb_mask;
        h2 += (load32_le(block + 6) >> 4) & limb_mask;
        h3 += (load32_le(block + 9) >> 6) & limb_mask;
        h4 += (load32_le(block + 12) >> 8) | high_bit;
        const std::uint64_t d0 = h0 * r0 + h1 * s4 + h2 * s3 + h3 * s2 + h4 * s1;
        const std::uint64_t d1 = h0 * r1 + h1 * r0 + h2 * s4 + h3 * s3 + h4 * s2;
        const std::uint64_t d2 = h0 * r2 + h1 * r1 + h2 * r0 + h3 * s4 + h4 * s3;
        const std::uint64_t d3 = h0 * r3 + h1 * r2 + h2 * r1 + h3 * r0 + h4 * s4;
        const std::uint64_t d4 = h0 * r4 + h1 * r3 + h2 * r2 + h3 * r1 + h4 * r0;
        std::uint64_t carry = d0 >> 26; h0 = d0 & limb_mask;
        std::uint64_t q1 = d1 + carry; carry = q1 >> 26; h1 = q1 & limb_mask;
        std::uint64_t q2 = d2 + carry; carry = q2 >> 26; h2 = q2 & limb_mask;
        std::uint64_t q3 = d3 + carry; carry = q3 >> 26; h3 = q3 & limb_mask;
        std::uint64_t q4 = d4 + carry; carry = q4 >> 26; h4 = q4 & limb_mask;
        h0 += carry * 5;
        carry = h0 >> 26; h0 &= limb_mask; h1 += carry;
        offset += block_length;
    }
    for (int pass = 0; pass < 3; ++pass) {
        std::uint64_t carry = h0 >> 26; h0 &= limb_mask; h1 += carry;
        carry = h1 >> 26; h1 &= limb_mask; h2 += carry;
        carry = h2 >> 26; h2 &= limb_mask; h3 += carry;
        carry = h3 >> 26; h3 &= limb_mask; h4 += carry;
        carry = h4 >> 26; h4 &= limb_mask; h0 += carry * 5;
        carry = h0 >> 26; h0 &= limb_mask; h1 += carry;
    }
    if (h4 == limb_mask && h3 == limb_mask && h2 == limb_mask && h1 == limb_mask && h0 >= limb_mask - 4) {
        h0 -= limb_mask - 4;
        h1 = h2 = h3 = h4 = 0;
    }
    const std::uint64_t f0 = ((h0 | (h1 << 26)) & 0xffffffffULL) + load32_le(key + 16);
    const std::uint64_t f1 = ((h1 >> 6 | (h2 << 20)) & 0xffffffffULL) + load32_le(key + 20) + (f0 >> 32);
    const std::uint64_t f2 = ((h2 >> 12 | (h3 << 14)) & 0xffffffffULL) + load32_le(key + 24) + (f1 >> 32);
    const std::uint64_t f3 = ((h3 >> 18 | (h4 << 8)) & 0xffffffffULL) + load32_le(key + 28) + (f2 >> 32);
    store32_le(tag + 0, static_cast<std::uint32_t>(f0));
    store32_le(tag + 4, static_cast<std::uint32_t>(f1));
    store32_le(tag + 8, static_cast<std::uint32_t>(f2));
    store32_le(tag + 12, static_cast<std::uint32_t>(f3));
}
}

extern "C" std::int64_t poly1305(const std::int64_t *input, std::size_t length,
                                  std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || length < 33 || length > max_input_length) return -1;
    const auto raw_length = input[0];
    if (raw_length < 0 || raw_length > static_cast<std::int64_t>(max_message_length) ||
        length != 33 + static_cast<std::size_t>(raw_length)) return -1;
    for (std::size_t i = 1; i < length; ++i) if (input[i] < 0 || input[i] > 255) return -1;
    if (output == nullptr || output_capacity < 16) return -2;
    std::uint8_t key[32], message[max_message_length]{}, tag[16];
    for (std::size_t i = 0; i < 32; ++i) key[i] = static_cast<std::uint8_t>(input[1 + i]);
    for (std::size_t i = 0; i < static_cast<std::size_t>(raw_length); ++i) message[i] = static_cast<std::uint8_t>(input[33 + i]);
    poly1305_tag(key, message, static_cast<std::size_t>(raw_length), tag);
    for (std::size_t i = 0; i < 16; ++i) output[i] = tag[i];
    return 16;
}
