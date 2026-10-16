#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_length = 10;
constexpr std::size_t packed_input_length = max_input_length + 1;
constexpr std::size_t output_length = 8;

bool is_digit(std::int64_t value) noexcept {
    return value >= 48 && value <= 57;
}
}

extern "C" std::int64_t railway_time_conversion(
    const std::int64_t *values, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept {
    if (values == nullptr || length != packed_input_length ||
        values[0] != static_cast<std::int64_t>(max_input_length)) return -1;

    if (values[3] != 58 || values[6] != 58 ||
        !((values[9] == 65 && values[10] == 77) ||
          (values[9] == 80 && values[10] == 77)) ||
        !is_digit(values[1]) || !is_digit(values[2]) ||
        !is_digit(values[4]) || !is_digit(values[5]) ||
        !is_digit(values[7]) || !is_digit(values[8])) return -1;

    const std::int64_t hour = (values[1] - 48) * 10 + values[2] - 48;
    const std::int64_t minute = (values[4] - 48) * 10 + values[5] - 48;
    const std::int64_t second = (values[7] - 48) * 10 + values[8] - 48;
    if (hour < 1 || hour > 12 || minute > 59 || second > 59) return -1;
    if (output == nullptr || output_capacity < output_length) return -2;

    const std::int64_t hour24 = hour % 12 + (values[9] == 80 ? 12 : 0);
    output[0] = static_cast<std::uint8_t>(48 + hour24 / 10);
    output[1] = static_cast<std::uint8_t>(48 + hour24 % 10);
    output[2] = 58;
    output[3] = static_cast<std::uint8_t>(values[4]);
    output[4] = static_cast<std::uint8_t>(values[5]);
    output[5] = 58;
    output[6] = static_cast<std::uint8_t>(values[7]);
    output[7] = static_cast<std::uint8_t>(values[8]);
    return static_cast<std::int64_t>(output_length);
}
