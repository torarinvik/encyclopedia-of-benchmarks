/* Clean-room bounded stable block-merge sort profile inspired by WikiSort. */
#include <stddef.h>
#include <stdint.h>

#define WIKISORT_CACHE_SIZE 512u
#define WIKISORT_RUN_SIZE 16u
#define WIKISORT_MAX_LENGTH 2048u

static void reverse_range(int64_t *values, size_t first, size_t last)
{
    while (first < last) {
        --last;
        if (first >= last) break;
        int64_t item = values[first];
        values[first] = values[last];
        values[last] = item;
        ++first;
    }
}

static void insertion_sort(int64_t *values, size_t first, size_t last)
{
    for (size_t index = first + 1; index < last; ++index) {
        int64_t item = values[index];
        size_t position = index;
        while (position > first && item < values[position - 1]) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = item;
    }
}

static void rotate_adjacent(int64_t *values, int64_t *scratch,
                            size_t first, size_t middle, size_t last,
                            size_t cache_size)
{
    size_t left_length = middle - first;
    size_t right_length = last - middle;
    if (left_length == 0 || right_length == 0) return;

    if (left_length <= right_length && left_length <= cache_size) {
        for (size_t index = 0; index < left_length; ++index)
            scratch[index] = values[first + index];
        for (size_t index = 0; index < right_length; ++index)
            values[first + index] = values[middle + index];
        for (size_t index = 0; index < left_length; ++index)
            values[first + right_length + index] = scratch[index];
        return;
    }
    if (right_length < left_length && right_length <= cache_size) {
        for (size_t index = 0; index < right_length; ++index)
            scratch[index] = values[middle + index];
        for (size_t index = left_length; index > 0; --index)
            values[first + right_length + index - 1] = values[first + index - 1];
        for (size_t index = 0; index < right_length; ++index)
            values[first + index] = scratch[index];
        return;
    }

    reverse_range(values, first, middle);
    reverse_range(values, middle, last);
    reverse_range(values, first, last);
}

static void merge_from_cache(int64_t *values, int64_t *scratch,
                             size_t first, size_t middle, size_t last)
{
    size_t left_length = middle - first;
    for (size_t index = 0; index < left_length; ++index)
        scratch[index] = values[first + index];

    size_t left = 0;
    size_t right = middle;
    size_t output = first;
    while (left < left_length && right < last) {
        if (scratch[left] <= values[right]) values[output++] = scratch[left++];
        else values[output++] = values[right++];
    }
    while (left < left_length) values[output++] = scratch[left++];
}

static void block_rotation_merge(int64_t *values, int64_t *scratch,
                                 size_t first, size_t middle, size_t last,
                                 size_t cache_size)
{
    size_t total = last - first;
    size_t block_size = 1;
    while (block_size + 1 <= total / (block_size + 1)) ++block_size;

    size_t left = first;
    while (left < middle && middle < last) {
        if (values[left] <= values[middle]) {
            int64_t boundary_value = values[middle];
            size_t low = left;
            size_t high = middle;
            while (low < high) {
                size_t probe = low + (high - low) / 2;
                if (values[probe] <= boundary_value) low = probe + 1;
                else high = probe;
            }
            left = low;
        } else {
            int64_t key = values[left];
            size_t low = middle;
            size_t high = last;
            while (low < high) {
                size_t probe = low + (high - low) / 2;
                if (values[probe] < key) low = probe + 1;
                else high = probe;
            }
            size_t block_end = low;
            if (block_end - middle > block_size) block_end = middle + block_size;
            size_t moved = block_end - middle;
            if (moved == 0) {
                ++left;
            } else {
                rotate_adjacent(values, scratch, left, middle, block_end, cache_size);
                left += moved;
                middle += moved;
            }
        }
    }
}

void wikisort(int64_t *values, int64_t *scratch, size_t length)
{
    if (length < 2 || length > WIKISORT_MAX_LENGTH) return;
    size_t cache_size = length < WIKISORT_CACHE_SIZE ? length : WIKISORT_CACHE_SIZE;
    if (length <= 32) {
        insertion_sort(values, 0, length);
        return;
    }

    for (size_t start = 0; start < length; start += WIKISORT_RUN_SIZE) {
        size_t end = start + WIKISORT_RUN_SIZE;
        if (end > length) end = length;
        insertion_sort(values, start, end);
    }

    for (size_t width = WIKISORT_RUN_SIZE; width < length;) {
        size_t first = 0;
        while (first < length) {
            size_t middle = first + width;
            if (middle > length) middle = length;
            size_t last = middle + width;
            if (last > length) last = length;

            if (middle < last && values[middle] < values[middle - 1]) {
                if (values[last - 1] < values[first]) {
                    rotate_adjacent(values, scratch, first, middle, last, cache_size);
                } else if (middle - first <= cache_size) {
                    merge_from_cache(values, scratch, first, middle, last);
                } else {
                    block_rotation_merge(values, scratch, first, middle, last,
                                         cache_size);
                }
            }
            first = last;
        }
        if (width > length / 2) break;
        width *= 2;
    }
}
