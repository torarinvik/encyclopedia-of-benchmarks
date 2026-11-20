/* Largest histogram rectangle using hanging-line reach links. */
#include <stddef.h>
#include <stdint.h>

#define HANGING_MAX_LENGTH 64
#define HANGING_MAX_HEIGHT 1000000
#define HANGING_INVALID INT64_MIN

int64_t hanging_line_largest_rectangle(const int64_t *heights, size_t length) {
    if (length == 0) return 0;
    if (heights == NULL || length > HANGING_MAX_LENGTH) return HANGING_INVALID;
    for (size_t i = 0; i < length; ++i) {
        if (heights[i] < 0 || heights[i] > HANGING_MAX_HEIGHT) return HANGING_INVALID;
    }

    size_t left[HANGING_MAX_LENGTH];
    size_t right[HANGING_MAX_LENGTH];
    for (size_t i = 0; i < length; ++i) {
        left[i] = i;
        while (left[i] > 0 && heights[i] <= heights[left[i] - 1])
            left[i] = left[left[i] - 1];
    }
    for (size_t i = length; i-- > 0;) {
        right[i] = i;
        while (right[i] + 1 < length && heights[i] <= heights[right[i] + 1])
            right[i] = right[right[i] + 1];
    }

    int64_t best = 0;
    for (size_t i = 0; i < length; ++i) {
        const int64_t width = (int64_t)(right[i] - left[i] + 1);
        const int64_t area = heights[i] * width;
        if (area > best) best = area;
    }
    return best;
}
