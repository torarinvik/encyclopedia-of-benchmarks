#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t key_bytes = 32, block_bytes = 16, input_bytes = 48;

std::uint8_t gf_mul(std::uint8_t left, std::uint8_t right)
{
    std::uint8_t result = 0;
    while (right != 0) {
        if (right & 1u) result ^= left;
        left = static_cast<std::uint8_t>((left << 1) ^ ((left & 0x80u) ? 0x1bu : 0u));
        right >>= 1;
    }
    return result;
}

std::uint8_t gf_pow(std::uint8_t value, unsigned exponent)
{
    std::uint8_t result = 1;
    while (exponent != 0) {
        if (exponent & 1u) result = gf_mul(result, value);
        value = gf_mul(value, value);
        exponent >>= 1;
    }
    return result;
}

std::uint8_t rotl8(std::uint8_t value, unsigned amount)
{
    return static_cast<std::uint8_t>((value << amount) | (value >> (8u - amount)));
}

std::array<std::uint8_t, 256> make_sbox()
{
    std::array<std::uint8_t, 256> sbox{};
    for (unsigned value = 0; value < 256; ++value) {
        const auto inverse = value == 0 ? 0 : gf_pow(static_cast<std::uint8_t>(value), 254);
        sbox[value] = static_cast<std::uint8_t>(inverse ^ rotl8(inverse, 1) ^ rotl8(inverse, 2) ^
            rotl8(inverse, 3) ^ rotl8(inverse, 4) ^ 0x63u);
    }
    return sbox;
}

std::array<std::uint8_t, 16> encrypt_block(const std::uint8_t *key, const std::uint8_t *block)
{
    const auto sbox = make_sbox();
    std::array<std::uint8_t, 240> round_keys{};
    constexpr std::array<std::uint8_t, 7> round_constants{1, 2, 4, 8, 16, 32, 64};
    for (std::size_t i = 0; i < key_bytes; ++i) round_keys[i] = key[i];
    std::size_t written = key_bytes;
    while (written < round_keys.size()) {
        const unsigned word = static_cast<unsigned>(written / 4);
        std::array<std::uint8_t, 4> temporary{};
        for (unsigned j = 0; j < 4; ++j) temporary[j] = round_keys[written - 4 + j];
        if (word % 8 == 0) {
            const auto first = temporary[0];
            temporary[0] = sbox[temporary[1]] ^ round_constants[word / 8 - 1];
            temporary[1] = sbox[temporary[2]];
            temporary[2] = sbox[temporary[3]];
            temporary[3] = sbox[first];
        } else if (word % 8 == 4) {
            for (auto &byte : temporary) byte = sbox[byte];
        }
        for (unsigned j = 0; j < 4; ++j) {
            round_keys[written] = round_keys[written - 32] ^ temporary[j];
            ++written;
        }
    }

    std::array<std::uint8_t, 16> state{};
    for (unsigned i = 0; i < 16; ++i) state[i] = block[i] ^ round_keys[i];
    for (unsigned round = 1; round < 14; ++round) {
        for (auto &byte : state) byte = sbox[byte];
        auto previous = state;
        for (unsigned column = 0; column < 4; ++column)
            for (unsigned row = 0; row < 4; ++row)
                state[row + 4 * column] = previous[row + 4 * ((column + row) % 4)];
        for (unsigned column = 0; column < 4; ++column) {
            const unsigned offset = 4 * column;
            const auto a = state[offset], b = state[offset + 1];
            const auto c = state[offset + 2], d = state[offset + 3];
            const auto total = static_cast<std::uint8_t>(a ^ b ^ c ^ d);
            state[offset] = a ^ total ^ gf_mul(a ^ b, 2);
            state[offset + 1] = b ^ total ^ gf_mul(b ^ c, 2);
            state[offset + 2] = c ^ total ^ gf_mul(c ^ d, 2);
            state[offset + 3] = d ^ total ^ gf_mul(d ^ a, 2);
        }
        const unsigned key_offset = round * 16;
        for (unsigned i = 0; i < 16; ++i) state[i] ^= round_keys[key_offset + i];
    }
    for (auto &byte : state) byte = sbox[byte];
    auto previous = state;
    for (unsigned column = 0; column < 4; ++column)
        for (unsigned row = 0; row < 4; ++row)
            state[row + 4 * column] = previous[row + 4 * ((column + row) % 4)];
    for (unsigned i = 0; i < 16; ++i) state[i] ^= round_keys[224 + i];
    return state;
}
}

extern "C" std::int64_t mibench_security_rijndael(const std::int64_t *values, std::size_t length,
                                                   std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length != input_bytes) return -1;
    for (std::size_t i = 0; i < input_bytes; ++i)
        if (values[i] < 0 || values[i] > 255) return -1;
    if (output == nullptr || output_capacity < block_bytes) return -2;
    std::array<std::uint8_t, 16> key{}, block{};
    for (std::size_t i = 0; i < key_bytes; ++i) key[i] = static_cast<std::uint8_t>(values[i]);
    for (std::size_t i = 0; i < block_bytes; ++i) block[i] = static_cast<std::uint8_t>(values[key_bytes + i]);
    const auto ciphertext = encrypt_block(key.data(), block.data());
    for (std::size_t i = 0; i < block_bytes; ++i) output[i] = ciphertext[i];
    return static_cast<std::int64_t>(block_bytes);
}
