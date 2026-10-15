/* Check whether an ASCII string is a palindrome ignoring ASCII letter case. */
#include <cstddef>
#include <cstdint>

static std::int64_t ascii_lower(std::int64_t value) noexcept {
    return value >= 65 && value <= 90 ? value + 32 : value;
}

extern "C" std::int64_t case_insensitive_palindrome(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > 4096) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 127) return -1;
    }
    for (std::size_t left = 0; left < length / 2; ++left) {
        if (ascii_lower(values[left]) != ascii_lower(values[length - 1 - left])) return 0;
    }
    return 1;
}
