/* Replay a bounded forward Fisher–Yates shuffle using explicit draw offsets. */
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_length = 256;
constexpr std::size_t max_parseable_input_length = 513;

bool exact_integer_in_range(double value, std::int64_t minimum, std::int64_t maximum,
                            std::int64_t& integer) noexcept {
    if (!std::isfinite(value) || value < static_cast<double>(minimum) ||
        value > static_cast<double>(maximum)) return false;
    const auto converted = static_cast<std::int64_t>(value);
    if (static_cast<double>(converted) != value) return false;
    integer = converted;
    return true;
}
}

extern "C" std::int64_t shuffle(const double* input, std::size_t input_length,
                                 double* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 1 || input_length > max_parseable_input_length) return -1;

    std::int64_t count_value;
    if (!exact_integer_in_range(input[0], 0, static_cast<std::int64_t>(max_length), count_value)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    const std::size_t offset_count = count > 0 ? count - 1 : 0;
    const std::size_t expected_length = 1 + count + offset_count;
    if (input_length != expected_length) return -1;

    std::int64_t values[max_length]{};
    std::size_t offsets[max_length]{};
    for (std::size_t index = 0; index < count; ++index) {
        std::int64_t value;
        if (!exact_integer_in_range(input[1 + index], INT32_MIN, INT32_MAX, value)) return -1;
        values[index] = value;
    }
    for (std::size_t index = 0; index < offset_count; ++index) {
        std::int64_t offset;
        const auto maximum_offset = static_cast<std::int64_t>(count - 1 - index);
        if (!exact_integer_in_range(input[1 + count + index], 0, maximum_offset, offset)) return -1;
        offsets[index] = static_cast<std::size_t>(offset);
    }

    if (output == nullptr || output_capacity < count) return -2;
    for (std::size_t index = 0; index < offset_count; ++index) {
        const auto other = index + offsets[index];
        const auto temporary = values[index];
        values[index] = values[other];
        values[other] = temporary;
    }
    for (std::size_t index = 0; index < count; ++index) output[index] = static_cast<double>(values[index]);
    return static_cast<std::int64_t>(count);
}
