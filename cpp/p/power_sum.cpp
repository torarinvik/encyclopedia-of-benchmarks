/* Count distinct positive bases whose powers sum to the target. */
#include <cstddef>
#include <cstdint>

namespace {
std::int64_t search(std::int64_t target, std::int64_t power,
                    std::int64_t base, std::int64_t current_sum) noexcept
{
    std::int64_t term = 1;
    for (std::int64_t exponent = 0; exponent < power; ++exponent) term *= base;
    const auto new_sum = current_sum + term;
    if (new_sum == target) return 1;
    if (new_sum > target) return 0;
    return search(target, power, base + 1, new_sum)
         + search(target, power, base + 1, current_sum);
}
}

extern "C" std::int64_t power_sum(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length != 2) return -1;
    const auto target = packed[0];
    const auto power = packed[1];
    if (target < 1 || target > 1000 || power < 2 || power > 10) return -1;
    return search(target, power, 1, 0);
}
