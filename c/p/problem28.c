/* Bounded port of TheAlgorithms/Python Project Euler 28 layer summation. */
#include <stdint.h>

int64_t problem28(int64_t size)
{
    if (size < 0 || size > 100000) return -1;
    int64_t total = 1;
    const int64_t layer_count = (size + 1) / 2;
    for (int64_t layer = 1; layer < layer_count; ++layer) {
        const int64_t odd_corner = 2 * layer + 1;
        const int64_t even_corner = 2 * layer;
        total += 4 * odd_corner * odd_corner - 6 * even_corner;
    }
    return total;
}
