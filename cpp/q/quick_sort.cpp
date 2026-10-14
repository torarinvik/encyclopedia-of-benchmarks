/* Portable last-pivot quicksort; recursion is limited to the smaller side. */
#include <cstddef>
#include <cstdint>

static std::size_t partition(std::int64_t *values, std::size_t low, std::size_t high) noexcept
{
    const std::int64_t pivot = values[high - 1];
    std::size_t boundary = low;
    for (std::size_t scan = low; scan < high - 1; ++scan) {
        if (values[scan] <= pivot) {
            const std::int64_t temporary = values[boundary];
            values[boundary] = values[scan];
            values[scan] = temporary;
            ++boundary;
        }
    }
    const std::int64_t temporary = values[boundary];
    values[boundary] = values[high - 1];
    values[high - 1] = temporary;
    return boundary;
}

static void quick_sort_range(std::int64_t *values, std::size_t low_value, std::size_t high_value) noexcept
{
    std::size_t low = low_value;
    std::size_t high = high_value;
    while (high - low > 1) {
        const std::size_t pivot = partition(values, low, high);
        const std::size_t right_start = pivot + 1;
        if (pivot - low < high - right_start) {
            quick_sort_range(values, low, pivot);
            low = right_start;
        } else {
            quick_sort_range(values, right_start, high);
            high = pivot;
        }
    }
}

extern "C" void quick_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length > 1) quick_sort_range(values, 0, length);
}
