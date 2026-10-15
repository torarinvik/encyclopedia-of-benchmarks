/* Count vertex-simple directed paths with recursive DFS. */
#include <stddef.h>
#include <stdint.h>

static uint32_t count_from(const int64_t *matrix, uint32_t n, uint32_t current,
                           uint32_t destination, uint32_t visited)
{
    if (current == destination) return 1;
    visited |= (uint32_t)1 << current;
    uint32_t count = 0;
    for (uint32_t next = 0; next < n; ++next) {
        if (matrix[(size_t)current * n + next] == 1 &&
            (visited & ((uint32_t)1 << next)) == 0) {
            count += count_from(matrix, n, next, destination, visited);
        }
    }
    return count;
}

int64_t number_of_paths(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || values[0] < 1 || values[0] > 10) return -1;
    uint32_t n = (uint32_t)values[0];
    if (length != (size_t)3 + (size_t)n * n) return -1;
    if (values[1] < 0 || values[1] > UINT32_MAX || values[2] < 0 || values[2] > UINT32_MAX)
        return -1;
    for (size_t i = 3; i < length; ++i) if (values[i] != 0 && values[i] != 1) return -1;
    uint32_t source = (uint32_t)values[1], destination = (uint32_t)values[2];
    if (source >= n || destination >= n) return 0;
    return count_from(values + 3, n, source, destination, 0);
}
