#include <cstdint>

extern "C" std::int64_t problem100(std::int64_t min_total) noexcept
{
    if (min_total < 0 || min_total > 1'000'000'000'000LL) return -1;
    std::int64_t previous_numerator = 1;
    std::int64_t previous_denominator = 0;
    std::int64_t numerator = 1;
    std::int64_t denominator = 1;
    while (numerator <= 2 * min_total - 1) {
        previous_numerator += 2 * numerator;
        numerator += 2 * previous_numerator;
        previous_denominator += 2 * denominator;
        denominator += 2 * previous_denominator;
    }
    return (denominator + 1) / 2;
}
