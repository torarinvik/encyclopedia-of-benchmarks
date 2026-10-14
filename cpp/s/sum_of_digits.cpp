/* Add the decimal digits of the absolute value of a signed 32-bit integer. */
#include <cstdint>

extern "C" std::int64_t sum_of_digits(std::int64_t input) noexcept
{
    if (input < INT32_MIN || input > INT32_MAX) return -1;
    auto remaining = static_cast<std::uint64_t>(input < 0 ? -input : input);
    std::int64_t total = 0;
    while (remaining != 0) {
        total += static_cast<std::int64_t>(remaining % 10);
        remaining /= 10;
    }
    return total;
}
