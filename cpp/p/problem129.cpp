/* Search odd divisors for the first source repunit length exceeding limit. */
#include <cstdint>

namespace { constexpr std::int64_t MAX_LIMIT = 1'000'000; }

static std::int64_t least_divisible_repunit(std::int64_t divisor) noexcept
{
    if (divisor % 5 == 0 || divisor % 2 == 0) return 0;
    std::int64_t repunit = 1;
    std::int64_t repunit_index = 1;
    while (repunit != 0) {
        repunit = (10 * repunit + 1) % divisor;
        ++repunit_index;
    }
    return repunit_index;
}

extern "C" std::int64_t problem129(std::int64_t limit) noexcept
{
    if (limit < 1 || limit > MAX_LIMIT) return -1;
    auto divisor = limit - 1;
    if (divisor % 2 == 0) ++divisor;
    while (least_divisible_repunit(divisor) <= limit) divisor += 2;
    return divisor;
}
