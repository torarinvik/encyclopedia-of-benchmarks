/* Portable 0-based max-heap sort for signed 64-bit values. */
#include <stddef.h>
#include <stdint.h>

static void sift_down(int64_t *values, size_t root, size_t end)
{
    while (root < end / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        const int64_t temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

void heap_sort(int64_t *values, size_t length)
{
    for (size_t start = length / 2; start > 0;) {
        --start;
        sift_down(values, start, length);
    }
    for (size_t end = length; end > 1;) {
        --end;
        const int64_t temporary = values[0];
        values[0] = values[end];
        values[end] = temporary;
        sift_down(values, 0, end);
    }
}
