#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_message_bytes = 4096;
constexpr std::size_t max_parseable_input_length = 4099;
constexpr std::size_t max_output_bytes = 64;
constexpr std::array<std::uint64_t, 24> round_constants = {
    UINT64_C(0x0000000000000001), UINT64_C(0x0000000000008082),
    UINT64_C(0x800000000000808a), UINT64_C(0x8000000080008000),
    UINT64_C(0x000000000000808b), UINT64_C(0x0000000080000001),
    UINT64_C(0x8000000080008081), UINT64_C(0x8000000000008009),
    UINT64_C(0x000000000000008a), UINT64_C(0x0000000000000088),
    UINT64_C(0x0000000080008009), UINT64_C(0x000000008000000a),
    UINT64_C(0x000000008000808b), UINT64_C(0x800000000000008b),
    UINT64_C(0x8000000000008089), UINT64_C(0x8000000000008003),
    UINT64_C(0x8000000000008002), UINT64_C(0x8000000000000080),
    UINT64_C(0x000000000000800a), UINT64_C(0x800000008000000a),
    UINT64_C(0x8000000080008081), UINT64_C(0x8000000000008080),
    UINT64_C(0x0000000080000001), UINT64_C(0x8000000080008008)
};
constexpr std::array<unsigned, 25> rotation_offsets = {
    0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43,
    25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14
};

std::uint64_t rotate_left(std::uint64_t value, unsigned amount) noexcept
{
    if (amount == 0) return value;
    return (value << amount) | (value >> (64 - amount));
}

void keccak_f(std::array<std::uint64_t, 25> &state) noexcept
{
    std::array<std::uint64_t, 5> column{};
    std::array<std::uint64_t, 5> delta{};
    std::array<std::uint64_t, 25> moved{};
    for (std::size_t round = 0; round < 24; ++round) {
        for (std::size_t x = 0; x < 5; ++x)
            column[x] = state[x] ^ state[x + 5] ^ state[x + 10] ^ state[x + 15] ^ state[x + 20];
        for (std::size_t x = 0; x < 5; ++x)
            delta[x] = column[(x + 4) % 5] ^ rotate_left(column[(x + 1) % 5], 1);
        for (std::size_t y = 0; y < 5; ++y)
            for (std::size_t x = 0; x < 5; ++x)
                state[x + 5 * y] ^= delta[x];

        for (std::size_t y = 0; y < 5; ++y) {
            for (std::size_t x = 0; x < 5; ++x) {
                const auto source = x + 5 * y;
                moved[y + 5 * ((2 * x + 3 * y) % 5)] = rotate_left(state[source], rotation_offsets[source]);
            }
        }
        for (std::size_t y = 0; y < 5; ++y)
            for (std::size_t x = 0; x < 5; ++x)
                state[x + 5 * y] = moved[x + 5 * y] ^
                    ((~moved[(x + 1) % 5 + 5 * y]) & moved[(x + 2) % 5 + 5 * y]);
        state[0] ^= round_constants[round];
    }
}

void absorb_byte(std::array<std::uint64_t, 25> &state, std::size_t offset, std::uint8_t value) noexcept
{
    state[offset / 8] ^= static_cast<std::uint64_t>(value) << ((offset % 8) * 8);
}
}

extern "C" std::int64_t sha3(const std::int64_t *values, std::size_t length,
                             std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 2 || length > max_parseable_input_length) return -1;
    if (values[0] < 0 || values[0] > 3 || values[1] < 0 || values[1] > static_cast<std::int64_t>(max_message_bytes)) return -1;
    const auto variant = static_cast<std::size_t>(values[0]);
    const auto message_length = static_cast<std::size_t>(values[1]);
    if (length != 2 + message_length) return -1;
    for (std::size_t index = 0; index < message_length; ++index)
        if (values[2 + index] < 0 || values[2 + index] > 255) return -1;

    constexpr std::array<std::size_t, 4> digest_lengths = {28, 32, 48, 64};
    constexpr std::array<std::size_t, 4> rates = {144, 136, 104, 72};
    const auto digest_length = digest_lengths[variant];
    const auto rate = rates[variant];
    if (digest_length > max_output_bytes) return -1;
    if (output == nullptr || output_capacity < digest_length) return -2;

    std::array<std::uint64_t, 25> state{};
    std::size_t offset = 0;
    while (message_length - offset >= rate) {
        for (std::size_t index = 0; index < rate; ++index)
            absorb_byte(state, index, static_cast<std::uint8_t>(values[2 + offset + index]));
        keccak_f(state);
        offset += rate;
    }

    std::array<std::uint8_t, 144> block{};
    const auto remaining = message_length - offset;
    for (std::size_t index = 0; index < remaining; ++index)
        block[index] = static_cast<std::uint8_t>(values[2 + offset + index]);
    block[remaining] ^= UINT8_C(0x06);
    block[rate - 1] ^= UINT8_C(0x80);
    for (std::size_t index = 0; index < rate; ++index) absorb_byte(state, index, block[index]);
    keccak_f(state);

    for (std::size_t index = 0; index < digest_length; ++index)
        output[index] = static_cast<std::uint8_t>(state[index / 8] >> ((index % 8) * 8));
    return static_cast<std::int64_t>(digest_length);
}
