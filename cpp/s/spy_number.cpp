/* Return whether a positive integer's decimal digit sum equals its product. */
#include <cstdint>

extern "C" std::int64_t spy_number(std::int64_t input) noexcept
{
    if (input <= 0) return 0;
    std::int64_t digit_sum = 0;
    std::int64_t digit_product = 1;
    while (input > 0) {
        const auto digit = input % 10;
        digit_sum += digit;
        digit_product *= digit;
        input /= 10;
    }
    return digit_sum == digit_product ? 1 : 0;
}
