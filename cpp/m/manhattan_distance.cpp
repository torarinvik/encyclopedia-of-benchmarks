// Return the n-dimensional Manhattan distance between two integer points.
#include <cstddef>
#include <cstdint>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double manhattan_distance(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 3) return INVALID_RESULT;
    const auto dimensions = values[0];
    if (dimensions < 1 || dimensions > 16 || length != 1 + 2 * static_cast<std::size_t>(dimensions)) return INVALID_RESULT;
    std::int64_t total = 0;
    for (std::size_t index = 0; index < static_cast<std::size_t>(dimensions); ++index) {
        const auto first = values[1 + index];
        const auto second = values[1 + static_cast<std::size_t>(dimensions) + index];
        if (first < -1000000 || first > 1000000 || second < -1000000 || second > 1000000) return INVALID_RESULT;
        const auto difference = first - second;
        total += difference < 0 ? -difference : difference;
    }
    return static_cast<double>(total);
}
