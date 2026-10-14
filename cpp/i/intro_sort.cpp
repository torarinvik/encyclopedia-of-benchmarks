/* Introsort with a quicksort depth limit, heapsort fallback, and insertion cutoff. */
#include <cstddef>
#include <cstdint>

namespace {
void swap_i64(std::int64_t *values, std::size_t left, std::size_t right) noexcept
{
    const std::int64_t temporary = values[left];
    values[left] = values[right];
    values[right] = temporary;
}

void insertion_sort_range(std::int64_t *values, std::size_t low, std::size_t high) noexcept
{
    for (std::size_t index = low + 1; index < high; ++index) {
        const std::int64_t key = values[index];
        std::size_t cursor = index;
        while (cursor > low && values[cursor - 1] > key) {
            values[cursor] = values[cursor - 1];
            --cursor;
        }
        values[cursor] = key;
    }
}

void sift_down(std::int64_t *values, std::size_t start, std::size_t count, std::size_t root) noexcept
{
    while (root < count / 2) {
        std::size_t child = root * 2 + 1;
        if (child + 1 < count && values[start + child] < values[start + child + 1]) ++child;
        if (values[start + root] >= values[start + child]) return;
        swap_i64(values, start + root, start + child);
        root = child;
    }
}

void heap_sort_range(std::int64_t *values, std::size_t low, std::size_t count) noexcept
{
    for (std::size_t parent = count / 2; parent > 0;) {
        --parent;
        sift_down(values, low, count, parent);
    }
    for (std::size_t end = count; end > 1;) {
        --end;
        swap_i64(values, low, low + end);
        sift_down(values, low, end, 0);
    }
}

std::size_t partition_range(std::int64_t *values, std::size_t low, std::size_t high) noexcept
{
    const std::size_t last = high - 1;
    const std::size_t pivot_index = low + (high - low) / 2;
    swap_i64(values, pivot_index, last);
    const std::int64_t pivot = values[last];
    std::size_t boundary = low;
    for (std::size_t probe = low; probe < last; ++probe) {
        if (values[probe] <= pivot) {
            swap_i64(values, boundary, probe);
            ++boundary;
        }
    }
    swap_i64(values, boundary, last);
    return boundary;
}

void intro_sort_range(std::int64_t *values, std::size_t low, std::size_t high, std::size_t depth) noexcept
{
    const std::size_t count = high - low;
    if (count <= 16) {
        insertion_sort_range(values, low, high);
        return;
    }
    if (depth == 0) {
        heap_sort_range(values, low, count);
        return;
    }
    const std::size_t pivot = partition_range(values, low, high);
    intro_sort_range(values, low, pivot, depth - 1);
    intro_sort_range(values, pivot + 1, high, depth - 1);
}

std::size_t depth_limit(std::size_t length) noexcept
{
    std::size_t logarithm = 0;
    while (length > 1) {
        length >>= 1;
        ++logarithm;
    }
    return logarithm * 2;
}
}

extern "C" void intro_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length < 2) return;
    intro_sort_range(values, 0, length, depth_limit(length));
}
