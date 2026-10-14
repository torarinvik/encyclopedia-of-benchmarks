/* Introsort with a quicksort depth limit, heapsort fallback, and insertion cutoff. */
#include <stddef.h>
#include <stdint.h>

static void swap_i64(int64_t *values, size_t left, size_t right)
{
    const int64_t temporary = values[left];
    values[left] = values[right];
    values[right] = temporary;
}

static void insertion_sort_range(int64_t *values, size_t low, size_t high)
{
    for (size_t index = low + 1; index < high; ++index) {
        const int64_t key = values[index];
        size_t cursor = index;
        while (cursor > low && values[cursor - 1] > key) {
            values[cursor] = values[cursor - 1];
            --cursor;
        }
        values[cursor] = key;
    }
}

static void sift_down(int64_t *values, size_t start, size_t count, size_t root)
{
    while (root < count / 2) {
        size_t child = root * 2 + 1;
        if (child + 1 < count && values[start + child] < values[start + child + 1]) {
            ++child;
        }
        if (values[start + root] >= values[start + child]) return;
        swap_i64(values, start + root, start + child);
        root = child;
    }
}

static void heap_sort_range(int64_t *values, size_t low, size_t count)
{
    for (size_t parent = count / 2; parent > 0;) {
        --parent;
        sift_down(values, low, count, parent);
    }
    for (size_t end = count; end > 1;) {
        --end;
        swap_i64(values, low, low + end);
        sift_down(values, low, end, 0);
    }
}

static size_t partition_range(int64_t *values, size_t low, size_t high)
{
    const size_t last = high - 1;
    const size_t pivot_index = low + (high - low) / 2;
    swap_i64(values, pivot_index, last);
    const int64_t pivot = values[last];
    size_t boundary = low;
    for (size_t probe = low; probe < last; ++probe) {
        if (values[probe] <= pivot) {
            swap_i64(values, boundary, probe);
            ++boundary;
        }
    }
    swap_i64(values, boundary, last);
    return boundary;
}

static void intro_sort_range(int64_t *values, size_t low, size_t high, size_t depth)
{
    const size_t count = high - low;
    if (count <= 16) {
        insertion_sort_range(values, low, high);
        return;
    }
    if (depth == 0) {
        heap_sort_range(values, low, count);
        return;
    }
    const size_t pivot = partition_range(values, low, high);
    intro_sort_range(values, low, pivot, depth - 1);
    intro_sort_range(values, pivot + 1, high, depth - 1);
}

static size_t depth_limit(size_t length)
{
    size_t logarithm = 0;
    while (length > 1) {
        length >>= 1;
        ++logarithm;
    }
    return logarithm * 2;
}

void intro_sort(int64_t *values, size_t length)
{
    if (length < 2) return;
    intro_sort_range(values, 0, length, depth_limit(length));
}
