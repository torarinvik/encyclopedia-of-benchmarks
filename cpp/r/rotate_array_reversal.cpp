// Rotate by reversing the whole array, then each side of the rotation.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_array_length = 1024;
constexpr std::size_t max_input_length = max_array_length + 1;

void reverse_range(std::int32_t *values, std::size_t start, std::size_t end) noexcept {
    while (start < end) {
        --end;
        if (start >= end) break;
        const auto temporary = values[start];
        values[start] = values[end];
        values[end] = temporary;
        ++start;
    }
}
}

extern "C" std::int64_t rotate_array_reversal(const std::int64_t *input, std::size_t length,
                                               std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const auto steps = input[0];
    if (steps < std::numeric_limits<std::int32_t>::min() ||
        steps > std::numeric_limits<std::int32_t>::max()) return -1;
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
    std::size_t shift = 0;
    if (count != 0) {
        auto remainder = steps % static_cast<std::int64_t>(count);
        if (remainder < 0) remainder += static_cast<std::int64_t>(count);
        shift = static_cast<std::size_t>(remainder);
    }
    reverse_range(values, 0, count);
    reverse_range(values, 0, shift);
    reverse_range(values, shift, count);
    for (std::size_t index = 0; index < count; ++index) {
        const auto bits = static_cast<std::uint32_t>(values[index]);
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[index * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(count);
}
