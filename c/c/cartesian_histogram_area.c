/* Uncompiled and unexecuted Cartesian-tree histogram draft. */
#include <stddef.h>
#include <stdint.h>
#include <limits.h>
int64_t cartesian_histogram_area(const int64_t *heights, size_t length) {
    if (length == 0) return 0;
    if (!heights || length > 64) return INT64_MIN;
    for (size_t i = 0; i < length; ++i) if (heights[i] < 0 || heights[i] > 1000000) return INT64_MIN;
    size_t left[64], right[64], stack[64], order[64], size[64] = {0};
    for (size_t i = 0; i < length; ++i) left[i] = right[i] = length;
    size_t top = 0;
    for (size_t i = 0; i < length; ++i) {
        size_t last = length;
        while (top && heights[stack[top-1]] > heights[i]) last = stack[--top];
        if (top) right[stack[top-1]] = i;
        left[i] = last; stack[top++] = i;
    }
    size_t root = stack[0], used = 0;
    top = 0; stack[top++] = root;
    while (top) {
        size_t node = stack[--top]; order[used++] = node;
        if (left[node] < length) stack[top++] = left[node];
        if (right[node] < length) stack[top++] = right[node];
    }
    int64_t best = 0;
    while (used) {
        size_t node = order[--used];
        size[node] = 1 + (left[node] < length ? size[left[node]] : 0)
                       + (right[node] < length ? size[right[node]] : 0);
        int64_t area = heights[node]*(int64_t)size[node];
        if (area > best) best = area;
    }
    return best;
}
