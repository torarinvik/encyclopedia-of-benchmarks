/* Return the n-dimensional Manhattan distance between two integer points. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double manhattan_distance(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3) return INVALID_RESULT;
    const int64_t dimensions = values[0];
    if (dimensions < 1 || dimensions > 16 || length != 1 + 2 * (size_t)dimensions) return INVALID_RESULT;
    int64_t total = 0;
    for (size_t index = 0; index < (size_t)dimensions; ++index) {
        const int64_t first = values[1 + index];
        const int64_t second = values[1 + (size_t)dimensions + index];
        if (first < -1000000 || first > 1000000 || second < -1000000 || second > 1000000)
            return INVALID_RESULT;
        const int64_t difference = first - second;
        total += difference < 0 ? -difference : difference;
    }
    return (double)total;
}
