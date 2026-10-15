/* Check whether a square can be split into two parts that sum to n. */
#include <cstdint>

extern "C" std::int64_t kaprekar_number(std::int64_t number) noexcept
{
    if (number < 1) return 0;
    if (number > 2'000'000'000LL) return -1;
    if (number == 1) return 1;
    const auto square = number * number;
    std::int64_t split = 10;
    while (split <= square) {
        const auto right = square % split;
        if (right > 0 && square / split + right == number) return 1;
        if (split > square / 10) break;
        split *= 10;
    }
    return 0;
}
