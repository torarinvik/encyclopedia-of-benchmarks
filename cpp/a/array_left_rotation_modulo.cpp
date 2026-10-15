// Return a new array left-rotated by Java's nonpositive and modulo rules.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_array_length = 1024;
constexpr std::size_t max_input_length = max_array_length + 1;

void write_i32_le(std::uint8_t *output, std::size_t index, std::int32_t value) noexcept {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[index * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t array_left_rotation_modulo(const std::int64_t *input, std::size_t length,
                                                   std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const auto rotations = input[0];
    if (rotations < std::numeric_limits<std::int32_t>::min() ||
        rotations > std::numeric_limits<std::int32_t>::max()) return -1;
    const std::size_t count = length - 1;
    std::int32_t values[max_array_length];
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = input[index + 1];
        if (value < std::numeric_limits<std::int32_t>::min() ||
            value > std::numeric_limits<std::int32_t>::max()) return -1;
        values[index] = static_cast<std::int32_t>(value);
    }
    if (count == 0) return 0;
    const std::size_t shift = rotations > 0 ? static_cast<std::size_t>(rotations % static_cast<std::int64_t>(count)) : 0;
    const std::size_t output_bytes = count * 4;
    if (output_capacity < output_bytes || output == nullptr) return -2;
    for (std::size_t index = shift; index < count; ++index)
        write_i32_le(output, index - shift, values[index]);
    for (std::size_t index = 0; index < shift; ++index)
        write_i32_le(output, count - shift + index, values[index]);
    return static_cast<std::int64_t>(count);
}

