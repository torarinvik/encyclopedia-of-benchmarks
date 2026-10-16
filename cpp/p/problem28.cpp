/* Bounded port of TheAlgorithms/Python Project Euler 28 layer summation. */
#include <cstdint>

extern "C" std::int64_t problem28(std::int64_t size) noexcept
{
    if (size < 0 || size > 100000) return -1;
    std::int64_t total = 1;
    const std::int64_t layer_count = (size + 1) / 2;
    for (std::int64_t layer = 1; layer < layer_count; ++layer) {
        const std::int64_t odd_corner = 2 * layer + 1;
        const std::int64_t even_corner = 2 * layer;
        total += 4 * odd_corner * odd_corner - 6 * even_corner;
    }
    return total;
}
