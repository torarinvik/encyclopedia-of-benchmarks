#include <stddef.h>
#include <stdint.h>

static int less_head(const int64_t values[16][16], const size_t positions[16],
                     size_t left, size_t right)
{
    const int64_t a = values[left][positions[left]];
    const int64_t b = values[right][positions[right]];
    return a < b || (a == b && left < right);
}

static void sift_down(size_t heap[16], size_t heap_size, size_t root,
                      const int64_t values[16][16], const size_t positions[16])
{
    for (;;) {
        size_t child = root * 2 + 1;
        if (child >= heap_size) return;
        if (child + 1 < heap_size && less_head(values, positions, heap[child + 1], heap[child])) ++child;
        if (!less_head(values, positions, heap[child], heap[root])) return;
        const size_t swap = heap[root]; heap[root] = heap[child]; heap[child] = swap;
        root = child;
    }
}

int64_t smallest_range(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2 || length > 273) return -1;
    const int64_t count_value = packed[0];
    if (count_value < 1 || count_value > 16) return -1;
    const size_t count = (size_t)count_value;
    int64_t values[16][16] = {{0}};
    size_t lengths[16] = {0}, positions[16] = {0}, heap[16] = {0};
    size_t offset = 1, total = 0;
    int64_t current_max = -1000000001;
    for (size_t i = 0; i < count; ++i) {
        if (offset >= length || packed[offset] < 1 || packed[offset] > 16) return -1;
        lengths[i] = (size_t)packed[offset++];
        if (lengths[i] > 256 - total || offset + lengths[i] > length) return -1;
        total += lengths[i];
        for (size_t j = 0; j < lengths[i]; ++j) {
            const int64_t value = packed[offset++];
            if (value < -1000000000 || value > 1000000000 || (j > 0 && value < values[i][j - 1])) return -1;
            values[i][j] = value;
        }
        heap[i] = i;
        if (values[i][0] > current_max) current_max = values[i][0];
    }
    if (offset != length) return -1;
    size_t heap_size = count;
    for (size_t i = heap_size / 2; i > 0; --i) sift_down(heap, heap_size, i - 1, values, positions);
    int64_t best_lo = 0, best_hi = 0, best_width = INT64_MAX;
    for (;;) {
        const size_t list = heap[0];
        const int64_t lo = values[list][positions[list]];
        const int64_t width = current_max - lo;
        if (width < best_width) { best_width = width; best_lo = lo; best_hi = current_max; }
        if (++positions[list] == lengths[list]) break;
        if (values[list][positions[list]] > current_max) current_max = values[list][positions[list]];
        sift_down(heap, heap_size, 0, values, positions);
    }
    return (best_lo + 1000000000) * INT64_C(2000000001) + (best_hi + 1000000000);
}
