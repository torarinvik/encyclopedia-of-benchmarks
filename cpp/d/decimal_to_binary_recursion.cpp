/* Recursively encode binary digits as a decimal integer, for inputs 0..1023. */
#include <cstdint>

namespace {
std::int64_t encode_binary_digits(std::int64_t value) noexcept {
    if (value == 0) return 0;
    return (value % 2) + 10 * encode_binary_digits(value / 2);
}
}

extern "C" std::int64_t decimal_to_binary_recursion(std::int64_t value) noexcept {
    if (value < 0 || value > 1023) return -1;
    return encode_binary_digits(value);
}
