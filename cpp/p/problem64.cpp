/* Count odd periods in square-root continued fractions. */
#include <cstdint>

namespace {
constexpr std::int64_t MAX_LIMIT = 10000;

std::int64_t integer_sqrt(std::int64_t value)
{
    std::int64_t low = 0;
    std::int64_t high = value + 1;
    while (high - low > 1) {
        const std::int64_t middle = low + (high - low) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle;
    }
    return low;
}

std::int64_t period_length(std::int64_t value, std::int64_t root)
{
    std::int64_t numerator = 0;
    std::int64_t denominator = 1;
    std::int64_t coefficient = root;
    std::int64_t period = 0;
    do {
        numerator = denominator * coefficient - numerator;
        denominator = (value - numerator * numerator) / denominator;
        coefficient = (root + numerator) / denominator;
        ++period;
    } while (coefficient != 2 * root);
    return period;
}
} // namespace

extern "C" std::int64_t problem64(std::int64_t inclusive_limit) noexcept
{
    if (inclusive_limit < 0 || inclusive_limit > MAX_LIMIT) return -1;
    std::int64_t count = 0;
    for (std::int64_t value = 2; value <= inclusive_limit; ++value) {
        const std::int64_t root = integer_sqrt(value);
        if (root * root == value) continue;
        if (period_length(value, root) % 2 == 1) ++count;
    }
    return count;
}
