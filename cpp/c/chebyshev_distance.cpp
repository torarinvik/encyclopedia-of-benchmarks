// Return the greatest absolute coordinate difference from packed points.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t chebyshev_distance(const std::int64_t *values, std::size_t length)
{
    if (length < 3) return -1;
    const std::int64_t dimension_value = values[0];
    if (dimension_value < 1 || dimension_value > 128) return -1;
    const std::size_t dimension = static_cast<std::size_t>(dimension_value);
    if (length != 1 + 2 * dimension) return -1;
    std::int64_t maximum = 0;
    for (std::size_t i = 0; i < dimension; ++i) {
        const std::int64_t a = values[1 + i];
        const std::int64_t b = values[1 + dimension + i];
        if (a < -1000000000 || a > 1000000000 || b < -1000000000 || b > 1000000000) return -1;
        std::int64_t difference = a - b;
        if (difference < 0) difference = -difference;
        if (difference > maximum) maximum = difference;
    }
    return maximum;
}
