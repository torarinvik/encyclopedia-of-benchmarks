/* Sum positive integers through the limit that are not sums of two abundant numbers. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_limit = 28'123;
}

extern "C" std::int64_t problem23(std::int64_t limit) noexcept
{
    if (limit < 0 || limit > max_limit) return -1;
    const auto bound = static_cast<std::size_t>(limit);
    std::int64_t proper_divisor_sums[max_limit + 1] = {};
    bool abundant[max_limit + 1] = {};
    bool representable[max_limit + 1] = {};

    for (std::size_t divisor = 1; divisor <= bound / 2; ++divisor) {
        for (std::size_t multiple = 2 * divisor; multiple <= bound; multiple += divisor) {
            proper_divisor_sums[multiple] += static_cast<std::int64_t>(divisor);
        }
    }
    for (std::size_t value = 12; value <= bound; ++value) {
        abundant[value] = proper_divisor_sums[value] > static_cast<std::int64_t>(value);
    }
    for (std::size_t left = 12; left <= bound; ++left) {
        if (!abundant[left]) continue;
        for (std::size_t right = left; right <= bound - left; ++right) {
            if (abundant[right]) representable[left + right] = true;
        }
    }

    std::int64_t total = 0;
    for (std::size_t value = 1; value <= bound; ++value) {
        if (!representable[value]) total += static_cast<std::int64_t>(value);
    }
    return total;
}
