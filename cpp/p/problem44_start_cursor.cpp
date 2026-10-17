/* Find the first pentagonal difference from a bounded start cursor. */
#include <cstdint>

namespace {
constexpr std::int64_t max_start = 2166;
constexpr std::int64_t max_high_index = 2167;

std::int64_t pentagonal(std::int64_t index) noexcept
{
    return index * (3 * index - 1) / 2;
}

std::int64_t integer_sqrt(std::int64_t value) noexcept
{
    std::int64_t low = 0, high = 20000;
    while (high - low > 1) {
        const auto middle = (low + high) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}

bool is_pentagonal(std::int64_t value) noexcept
{
    const auto discriminant = 24 * value + 1;
    const auto root = integer_sqrt(discriminant);
    return root * root == discriminant && (root + 1) % 6 == 0;
}
}

extern "C" std::int64_t problem44_start_cursor(std::int64_t start) noexcept
{
    if (start < 1 || start > max_start) return -1;
    for (auto high = start + 1; high <= max_high_index; ++high) {
        const auto high_value = pentagonal(high);
        for (auto low = high - 1; low > 0; --low) {
            const auto low_value = pentagonal(low);
            const auto difference = high_value - low_value;
            const auto sum = high_value + low_value;
            if (is_pentagonal(difference) && is_pentagonal(sum)) return difference;
        }
    }
    return -1;
}
