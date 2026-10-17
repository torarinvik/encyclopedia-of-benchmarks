#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_count = 256;
constexpr std::size_t max_input_length = 5;
constexpr std::size_t max_output_bytes = max_count * 4;

void write_u32_le(std::uint8_t *output, std::size_t index, std::uint32_t value) {
    const std::size_t offset = index * 4;
    output[offset] = static_cast<std::uint8_t>(value);
    output[offset + 1] = static_cast<std::uint8_t>(value >> 8);
    output[offset + 2] = static_cast<std::uint8_t>(value >> 16);
    output[offset + 3] = static_cast<std::uint8_t>(value >> 24);
}

std::uint32_t rotate_right(std::uint32_t value, std::uint32_t rotation) {
    const std::uint32_t left_shift = (32u - rotation) & 31u;
    return (value >> rotation) | (value << left_shift);
}
}

extern "C" std::int64_t pcg32_random(const std::int64_t *values,
                                     std::size_t length,
                                     std::uint8_t *output,
                                     std::size_t output_capacity) {
    if (values == nullptr || length < 4 || length > max_input_length) return -1;
    if (length != 4) return -1;

    const std::uint64_t seed = static_cast<std::uint64_t>(values[0]);
    const std::uint64_t multiplier = static_cast<std::uint64_t>(values[1]);
    const std::int64_t stream_value = values[2];
    const std::int64_t count_value = values[3];
    if (stream_value < 0 || count_value < 0 || count_value > 256) return -1;

    const auto increment = (static_cast<std::uint64_t>(stream_value) << 1) | 1u;
    std::uint64_t state = seed + increment;
    state = state * multiplier + increment;
    const std::size_t count = static_cast<std::size_t>(count_value);
    const std::size_t required_bytes = count * 4;
    if (required_bytes > max_output_bytes) return -1;
    if (output == nullptr || output_capacity < required_bytes) return -2;

    for (std::size_t index = 0; index < count; ++index) {
        std::uint64_t value = state;
        const std::uint32_t rotation = static_cast<std::uint32_t>(value >> 59);
        state = state * multiplier + increment;
        value ^= value >> 18;
        const auto xorshifted = static_cast<std::uint32_t>(value >> 27);
        write_u32_le(output, index, rotate_right(xorshifted, rotation));
    }
    return static_cast<std::int64_t>(required_bytes);
}
