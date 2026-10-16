/* First-element-pivot quicksort using Hoare's partition scheme. */
#include <cstddef>
#include <cstdint>

static std::size_t partition_range(std::int64_t *values, std::size_t low, std::size_t high) noexcept
{
    const std::int64_t pivot = values[low];
    std::size_t left = low;
    std::size_t right = high;
    for (;;) {
        while (values[left] < pivot) ++left;
        while (values[right] > pivot) --right;
        if (left >= right) return right;
        const std::int64_t temporary = values[left];
        values[left] = values[right];
        values[right] = temporary;
        ++left;
        --right;
    }
}

static void partition_sort_range(std::int64_t *values, std::size_t low, std::size_t high) noexcept
{
    if (low < high) {
        const std::size_t split = partition_range(values, low, high);
        partition_sort_range(values, low, split);
        partition_sort_range(values, split + 1, high);
    }
}

extern "C" void partition_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length > 1) partition_sort_range(values, 0, length - 1);
}
