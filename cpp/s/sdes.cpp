#include <cstddef>
#include <cstdint>

namespace {
constexpr std::uint8_t p8[8] = {6, 3, 7, 4, 8, 5, 10, 9};
constexpr std::uint8_t p10[10] = {3, 5, 2, 7, 4, 10, 1, 9, 8, 6};
constexpr std::uint8_t p4[4] = {2, 4, 3, 1};
constexpr std::uint8_t ip[8] = {2, 6, 3, 1, 4, 8, 5, 7};
constexpr std::uint8_t ip_inverse[8] = {4, 1, 3, 5, 7, 2, 8, 6};
constexpr std::uint8_t expansion[8] = {4, 1, 2, 3, 2, 3, 4, 1};
constexpr std::uint8_t sboxes[2][4][4] = {
    {{1, 0, 3, 2}, {3, 2, 1, 0}, {0, 2, 1, 3}, {3, 1, 3, 2}},
    {{0, 1, 2, 3}, {2, 0, 1, 3}, {3, 0, 1, 0}, {2, 1, 0, 3}}
};

std::uint32_t table_value(std::uint32_t table, std::size_t index) {
    switch (table) {
        case 0: return p8[index];
        case 1: return p10[index];
        case 2: return ip[index];
        case 3: return ip_inverse[index];
        case 4: return expansion[index];
        default: return p4[index];
    }
}

std::uint32_t permute(std::uint32_t value, std::uint32_t input_bits,
                      std::uint32_t table, std::size_t count) {
    std::uint32_t result = 0;
    for (std::size_t index = 0; index < count; ++index) {
        const auto position = table_value(table, index);
        result = (result << 1) | ((value >> (input_bits - position)) & 1U);
    }
    return result;
}

std::uint32_t rotate5(std::uint32_t value, std::uint32_t amount) {
    return ((value << amount) | (value >> (5U - amount))) & 31U;
}

std::uint32_t subkey(std::uint32_t key, std::uint32_t round) {
    const auto selected = permute(key, 10, 1, 10);
    auto left = selected >> 5;
    auto right = selected & 31U;
    left = rotate5(left, 1);
    right = rotate5(right, 1);
    if (round != 0) {
        left = rotate5(left, 2);
        right = rotate5(right, 2);
    }
    return permute((left << 5) | right, 10, 0, 8);
}

std::uint32_t sbox_value(std::uint32_t box, std::uint32_t nibble) {
    const auto row = ((nibble & 8U) >> 2) | (nibble & 1U);
    const auto column = (nibble >> 1) & 3U;
    return sboxes[box][row][column];
}

std::uint32_t fk(std::uint32_t state, std::uint32_t key) {
    const auto left = state >> 4;
    const auto right = state & 15U;
    const auto mixed = permute(right, 4, 4, 8) ^ key;
    const auto substituted = (sbox_value(0, mixed >> 4) << 2) |
                             sbox_value(1, mixed & 15U);
    return ((left ^ permute(substituted, 4, 5, 4)) << 4) | right;
}

std::uint32_t crypt(std::uint32_t message, std::uint32_t key, bool decrypt) {
    const auto first = subkey(key, 0);
    const auto second = subkey(key, 1);
    auto state = permute(message, 8, 2, 8);
    state = fk(state, decrypt ? second : first);
    state = ((state & 15U) << 4) | (state >> 4);
    state = fk(state, decrypt ? first : second);
    return permute(state, 8, 3, 8);
}
} // namespace

// Return ciphertext and the plaintext recovered with the reversed subkeys.
extern "C" std::int64_t sdes(const std::int64_t *input, std::size_t length,
                             std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length != 2) return -1;
    if (input[0] < 0 || input[0] > 1023 || input[1] < 0 || input[1] > 255) return -1;
    if (output == nullptr || output_capacity < 2) return -2;
    const auto ciphertext = crypt(static_cast<std::uint32_t>(input[1]),
                                  static_cast<std::uint32_t>(input[0]), false);
    const auto recovered = crypt(ciphertext, static_cast<std::uint32_t>(input[0]), true);
    output[0] = static_cast<std::uint8_t>(ciphertext);
    output[1] = static_cast<std::uint8_t>(recovered);
    return 2;
}
