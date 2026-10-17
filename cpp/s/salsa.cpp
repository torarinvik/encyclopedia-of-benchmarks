#include <cstddef>
#include <cstdint>

namespace {
std::uint32_t rotate_left(std::uint32_t value, std::uint32_t amount) {
    return (value << amount) | (value >> (32U - amount));
}

void quarter_round(std::uint32_t *state, std::size_t first, std::size_t second,
                   std::size_t third, std::size_t fourth) {
    state[second] ^= rotate_left(state[first] + state[fourth], 7);
    state[third] ^= rotate_left(state[second] + state[first], 9);
    state[fourth] ^= rotate_left(state[third] + state[second], 13);
    state[first] ^= rotate_left(state[fourth] + state[third], 18);
}

void store_u32_le(std::uint8_t *output, std::size_t offset, std::uint32_t value) {
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(value >> (byte * 8));
}
} // namespace

// Reproduce the pinned 16-word Salsa core variant; this is not a stream cipher.
extern "C" std::int64_t salsa(const std::int32_t *input, std::size_t length,
                              std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length != 16) return -1;
    std::uint32_t original[16];
    for (std::size_t index = 0; index < 16; ++index) original[index] = static_cast<std::uint32_t>(input[index]);
    if (output == nullptr || output_capacity < 64) return -2;

    std::uint32_t state[16];
    for (std::size_t index = 0; index < 16; ++index) state[index] = original[index];
    for (std::size_t round = 0; round < 10; ++round) {
        quarter_round(state, 0, 4, 8, 12);
        quarter_round(state, 5, 9, 13, 1);
        quarter_round(state, 10, 14, 2, 6);
        quarter_round(state, 15, 3, 7, 11);
        quarter_round(state, 0, 1, 2, 3);
        quarter_round(state, 5, 6, 7, 4);
        quarter_round(state, 10, 11, 8, 9);
        quarter_round(state, 15, 12, 13, 14);
    }
    for (std::size_t index = 0; index < 16; ++index) {
        state[index] += original[index];
        store_u32_le(output, index * 4, state[index]);
    }
    return 64;
}
