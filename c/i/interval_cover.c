/* Greedy minimum subfamily covering a half-open target interval. */
#include <stddef.h>
#include <stdint.h>

int64_t interval_cover(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > 36) return -2;
    const int64_t target_left = input[0];
    const int64_t target_right = input[1];
    const int64_t count_value = input[2];
    if (target_left < 0 || target_left > target_right || target_right > 32
        || count_value < 0 || count_value > 16) return -2;
    const size_t count = (size_t)count_value;
    if (length != 3 + 2 * count) return -2;
    for (size_t i = 0; i < count; ++i) {
        const int64_t left = input[3 + 2 * i];
        const int64_t right = input[4 + 2 * i];
        if (left < 0 || left >= right || right > 32) return -2;
    }
    if (target_left == target_right) return 0;

    int64_t frontier = target_left;
    int64_t selected = 0;
    while (frontier < target_right) {
        int64_t farthest = frontier;
        for (size_t i = 0; i < count; ++i) {
            const int64_t left = input[3 + 2 * i];
            const int64_t right = input[4 + 2 * i];
            if (left <= frontier && right > farthest) farthest = right;
        }
        if (farthest == frontier) return -1;
        frontier = farthest;
        ++selected;
    }
    return selected;
}
