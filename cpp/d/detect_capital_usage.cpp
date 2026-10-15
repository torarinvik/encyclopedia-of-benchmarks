#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 1024; }
static bool is_upper(std::int64_t value) { return value >= 65 && value <= 90; }
static bool is_lower(std::int64_t value) { return value >= 97 && value <= 122; }
static bool valid_input(const std::int64_t *input, std::size_t length) {
    if (length > max_length || (length != 0 && input == nullptr)) return false;
    for (std::size_t index = 0; index < length; ++index)
        if (!is_upper(input[index]) && !is_lower(input[index])) return false;
    return true;
}

// Classify by counting uppercase letters.
extern "C" std::int64_t detect_capital_usage(const std::int64_t *input,
    std::size_t length) noexcept {
    if (!valid_input(input, length)) return -1;
    std::size_t uppercase_count = 0;
    for (std::size_t index = 0; index < length; ++index)
        if (is_upper(input[index])) ++uppercase_count;
    return uppercase_count == 0 || uppercase_count == length ||
           (uppercase_count == 1 && length != 0 && is_upper(input[0]));
}
