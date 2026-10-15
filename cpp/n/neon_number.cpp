/* A neon number equals the sum of the digits of its square. */
#include <cstdint>

extern "C" std::int64_t neon_number(std::int64_t number) noexcept
{
    if (number < 0) return 0;
    if (number > 3'000'000'000LL) return -1;
    auto square = number * number;
    std::int64_t digit_sum = 0;
    while (square > 0) {
        digit_sum += square % 10;
        square /= 10;
    }
    return digit_sum == number ? 1 : 0;
}
