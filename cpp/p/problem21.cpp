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

extern "C" std::int64_t problem21(std::int64_t limit) noexcept
{
    if (limit < 1 || limit > 10000) return -1;
    std::int64_t total = 0;
    for (std::int64_t value = 1; value < limit; ++value) {
        const std::int64_t partner = proper_divisor_sum(value);
        if (partner != value && proper_divisor_sum(partner) == value) total += value;
    }
    return total;
}
