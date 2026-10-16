#include <cstdint>

extern "C" std::int64_t sum_multiples_inclusion_exclusion(std::int64_t limit)
{
    if (limit < 1 || limit > 100'000) return -1;
    const std::int64_t last = limit - 1;
    const std::int64_t threes = last / 3;
    const std::int64_t fives = last / 5;
    const std::int64_t fifteens = last / 15;
    return 3 * threes * (threes + 1) / 2
         + 5 * fives * (fives + 1) / 2
         - 15 * fifteens * (fifteens + 1) / 2;
}
