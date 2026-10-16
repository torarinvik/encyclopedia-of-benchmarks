/* Find the next hexagonal number that is also pentagonal. */
#include <cstdint>

namespace {
std::int64_t integer_sqrt(std::int64_t value) noexcept
{
    std::int64_t low = 0, high = 200000;
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

extern "C" std::int64_t problem45(std::int64_t start) noexcept
{
    if (start < 0 || start > 27693) return -1;
    for (auto index = start; index <= 27693; ++index) {
        const auto value = index * (2 * index - 1);
        if (is_pentagonal(value)) return value;
    }
    return -1;
}
