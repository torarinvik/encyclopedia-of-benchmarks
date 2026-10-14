/* Check whether an exact ASCII string is a palindrome. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t palindrome(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > 4096) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 127) return -1;
    }
    for (std::size_t left = 0; left < length / 2; ++left) {
        if (values[left] != values[length - 1 - left]) return 0;
    }
    return 1;
}
