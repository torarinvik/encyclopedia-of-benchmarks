// Rotate an array right by repeating a one-place shift.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_array_length = 1024;
constexpr std::size_t max_input_length = max_array_length + 1;
constexpr std::int64_t max_rotations = 1024;
}

extern "C" std::int64_t rotate_array(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const std::int64_t rotations = input[0];
    if (rotations < 0 || rotations > max_rotations) return -1;
    const std::size_t count = length - 1;
    std::int32_t values[max_array_length];
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = input[index + 1];
        if (value < std::numeric_limits<std::int32_t>::min() ||
            value > std::numeric_limits<std::int32_t>::max()) return -1;
        values[index] = static_cast<std::int32_t>(value);
    }
    const std::size_t output_bytes = count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == nullptr)) return -2;
    for (std::int64_t step = 0; step < rotations && count > 1; ++step) {
        const std::int32_t last = values[count - 1];
        for (std::size_t index = count - 1; index > 0; --index) values[index] = values[index - 1];
        values[0] = last;
    }
    for (std::size_t index = 0; index < count; ++index) {
        const auto bits = static_cast<std::uint32_t>(values[index]);
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[index * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(count);
}
