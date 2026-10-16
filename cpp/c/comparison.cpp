#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_string_length = 64;
constexpr std::size_t max_input_length = 3 + 2 * max_string_length;

std::int64_t fold_ascii(std::int64_t value, std::int64_t mode) noexcept {
    if (mode == 1 && value >= 'A' && value <= 'Z') return value + ('a' - 'A');
    return value;
}
}  // namespace

extern "C" std::int64_t comparison(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 3 || length > max_input_length) return -2;
    const auto mode = values[0];
    const auto first_length_value = values[1];
    if ((mode != 0 && mode != 1) || first_length_value < 0
        || first_length_value > static_cast<std::int64_t>(max_string_length)) return -2;
    const auto first_length = static_cast<std::size_t>(first_length_value);
    const auto second_length_position = 2 + first_length;
    if (second_length_position >= length) return -2;
    const auto second_length_value = values[second_length_position];
    if (second_length_value < 0 || second_length_value > static_cast<std::int64_t>(max_string_length)) return -2;
    const auto second_length = static_cast<std::size_t>(second_length_value);
    const auto second_start = second_length_position + 1;
    if (second_start + second_length != length) return -2;

    for (std::size_t index = 0; index < first_length; ++index)
        if (values[2 + index] < 1 || values[2 + index] > 127) return -2;
    for (std::size_t index = 0; index < second_length; ++index)
        if (values[second_start + index] < 1 || values[second_start + index] > 127) return -2;

    const auto common_length = first_length < second_length ? first_length : second_length;
    for (std::size_t index = 0; index < common_length; ++index) {
        const auto left = fold_ascii(values[2 + index], mode);
        const auto right = fold_ascii(values[second_start + index], mode);
        if (left < right) return -1;
        if (left > right) return 1;
    }
    if (first_length < second_length) return -1;
    if (first_length > second_length) return 1;
    return 0;
}
