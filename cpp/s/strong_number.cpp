/* Check whether the sum of the decimal digits' factorials equals the input. */
#include <cstdint>

extern "C" std::int64_t strong_number(std::int64_t number) noexcept
{
    if (number < INT32_MIN || number > INT32_MAX) return -1;
    if (number < 0) return 0;
    auto remaining = number;
    std::int64_t sum = 0;
    if (remaining == 0) sum = 1;
    while (remaining > 0) {
        const auto digit = remaining % 10;
        std::int64_t factorial = 1;
        for (std::int64_t factor = 2; factor <= digit; ++factor) factorial *= factor;
        sum += factorial;
        remaining /= 10;
    }
    return sum == number ? 1 : 0;
}
