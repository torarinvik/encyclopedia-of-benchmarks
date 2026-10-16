#include <cstdint>

namespace {
constexpr std::int64_t max_binary_digit_numeral = 1111111111111111;
}

extern "C" std::int64_t twos_complement_of_binary(std::int64_t value) noexcept {
    if (value < 0 || value > max_binary_digit_numeral) return -1;
    if (value == 0) return 0;

    auto remaining = value;
    while (remaining > 0) {
        const auto digit = remaining % 10;
        if (digit != 0 && digit != 1) return -1;
        remaining /= 10;
    }

    remaining = value;
    std::int64_t reversed = 0;
    std::int64_t width = 0;
    while (remaining > 0 && remaining % 10 == 0) {
        reversed = reversed * 10 + remaining % 10;
        remaining /= 10;
        ++width;
    }
    if (remaining > 0) {
        reversed = reversed * 10 + remaining % 10;
        remaining /= 10;
        ++width;
    }
    while (remaining > 0) {
        const auto digit = remaining % 10;
        reversed = reversed * 10 + (digit == 1 ? 0 : 1);
        remaining /= 10;
        ++width;
    }

    std::int64_t result = 0;
    while (width > 0) {
        result = result * 10 + reversed % 10;
        reversed /= 10;
        --width;
    }
    return result;
}
