/* Clean-room bounded stable block-merge sort profile inspired by WikiSort. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t cache_capacity = 512;
constexpr std::size_t run_size = 16;
constexpr std::size_t maximum_length = 2048;

void reverse_range(std::int64_t *values, std::size_t first, std::size_t last) noexcept
{
    while (first < last) {
        --last;
        if (first >= last) break;
        const std::int64_t item = values[first];
        values[first] = values[last];
        values[last] = item;
        ++first;
    }
}

void insertion_sort(std::int64_t *values, std::size_t first, std::size_t last) noexcept
{
    for (std::size_t index = first + 1; index < last; ++index) {
        const std::int64_t item = values[index];
        std::size_t position = index;
        while (position > first && item < values[position - 1]) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = item;
    }
}

void rotate_adjacent(std::int64_t *values, std::int64_t *scratch,
                     std::size_t first, std::size_t middle, std::size_t last,
                     std::size_t cache_size) noexcept
{
    const std::size_t left_length = middle - first;
    const std::size_t right_length = last - middle;
    if (left_length == 0 || right_length == 0) return;
    if (left_length <= right_length && left_length <= cache_size) {
        for (std::size_t index = 0; index < left_length; ++index)
            scratch[index] = values[first + index];
        for (std::size_t index = 0; index < right_length; ++index)
            values[first + index] = values[middle + index];
        for (std::size_t index = 0; index < left_length; ++index)
            values[first + right_length + index] = scratch[index];
        return;
    }
    if (right_length < left_length && right_length <= cache_size) {
        for (std::size_t index = 0; index < right_length; ++index)
            scratch[index] = values[middle + index];
        for (std::size_t index = left_length; index > 0; --index)
            values[first + right_length + index - 1] = values[first + index - 1];
        for (std::size_t index = 0; index < right_length; ++index)
            values[first + index] = scratch[index];
        return;
    }
    reverse_range(values, first, middle);
    reverse_range(values, middle, last);
    reverse_range(values, first, last);
}

void merge_from_cache(std::int64_t *values, std::int64_t *scratch,
                      std::size_t first, std::size_t middle, std::size_t last) noexcept
{
    const std::size_t left_length = middle - first;
    for (std::size_t index = 0; index < left_length; ++index)
        scratch[index] = values[first + index];
    std::size_t left = 0;
    std::size_t right = middle;
    std::size_t output = first;
    while (left < left_length && right < last) {
        if (scratch[left] <= values[right]) values[output++] = scratch[left++];
        else values[output++] = values[right++];
    }
    while (left < left_length) values[output++] = scratch[left++];
}

void block_rotation_merge(std::int64_t *values, std::int64_t *scratch,
                          std::size_t first, std::size_t middle, std::size_t last,
                          std::size_t cache_size) noexcept
{
    const std::size_t total = last - first;
    std::size_t block_size = 1;
    while (block_size + 1 <= total / (block_size + 1)) ++block_size;
    std::size_t left = first;
    while (left < middle && middle < last) {
        if (values[left] <= values[middle]) {
            const std::int64_t boundary_value = values[middle];
            std::size_t low = left;
            std::size_t high = middle;
            while (low < high) {
                const std::size_t probe = low + (high - low) / 2;
                if (values[probe] <= boundary_value) low = probe + 1;
                else high = probe;
            }
            left = low;
        } else {
            const std::int64_t key = values[left];
            std::size_t low = middle;
            std::size_t high = last;
            while (low < high) {
                const std::size_t probe = low + (high - low) / 2;
                if (values[probe] < key) low = probe + 1;
                else high = probe;
            }
            std::size_t block_end = low;
            if (block_end - middle > block_size) block_end = middle + block_size;
            const std::size_t moved = block_end - middle;
            if (moved == 0) ++left;
            else {
                rotate_adjacent(values, scratch, left, middle, block_end, cache_size);
                left += moved;
                middle += moved;
            }
        }
    }
}
} // namespace

extern "C" void wikisort(std::int64_t *values, std::int64_t *scratch,
                          std::size_t length) noexcept
{
    if (length < 2 || length > maximum_length) return;
    const std::size_t cache_size = length < cache_capacity ? length : cache_capacity;
    if (length <= 32) {
        insertion_sort(values, 0, length);
        return;
    }
    for (std::size_t start = 0; start < length; start += run_size) {
        const std::size_t end = start + run_size < length ? start + run_size : length;
        insertion_sort(values, start, end);
    }
    for (std::size_t width = run_size; width < length;) {
        std::size_t first = 0;
        while (first < length) {
            const std::size_t middle = first + width < length ? first + width : length;
            const std::size_t last = middle + width < length ? middle + width : length;
            if (middle < last && values[middle] < values[middle - 1]) {
                if (values[last - 1] < values[first])
                    rotate_adjacent(values, scratch, first, middle, last, cache_size);
                else if (middle - first <= cache_size)
                    merge_from_cache(values, scratch, first, middle, last);
                else
                    block_rotation_merge(values, scratch, first, middle, last, cache_size);
            }
            first = last;
        }
        if (width > length / 2) break;
        width *= 2;
    }
}
