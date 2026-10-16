#include <cmath>
#include <cstdint>

namespace {
bool is_pentagonal(std::int64_t value) noexcept
{
    if (value < 1) return false;
    const std::int64_t discriminant = 24 * value + 1;
    const auto root = static_cast<std::int64_t>(std::sqrt(static_cast<double>(discriminant)));
    return root * root == discriminant && (root + 1) % 6 == 0;
}
}

extern "C" std::int64_t problem44(std::int64_t limit) noexcept
{
    if (limit < 1 || limit > 5000) return -1;
    for (std::int64_t i = 1; i < limit; ++i) {
        const auto first = i * (3 * i - 1) / 2;
        for (std::int64_t j = i; j < limit; ++j) {
            const auto second = j * (3 * j - 1) / 2;
            const auto difference = second - first;
            if (is_pentagonal(first + second) && is_pentagonal(difference)) return difference;
        }
    }
    return -1;
}
