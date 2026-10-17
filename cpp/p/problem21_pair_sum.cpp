#include <cstdint>

namespace {
std::int64_t proper_divisor_sum(std::int64_t value)
{
    if (value <= 1) return 0;
    std::int64_t sum = 1;
    for (std::int64_t divisor = 2; divisor <= value / divisor; ++divisor) {
        if (value % divisor != 0) continue;
        const std::int64_t partner = value / divisor;
        sum += divisor;
        if (partner != divisor) sum += partner;
    }
    return sum;
}
}

extern "C" std::int64_t problem21_pair_sum(std::int64_t limit) noexcept
{
    if (limit < 2 || limit > 10000) return -1;
    std::int64_t total = 0;
    for (std::int64_t smaller = 2; smaller < limit; ++smaller) {
        const std::int64_t larger = proper_divisor_sum(smaller);
        if (larger > smaller && proper_divisor_sum(larger) == smaller) {
            total += smaller + larger;
        }
    }
    return total;
}
