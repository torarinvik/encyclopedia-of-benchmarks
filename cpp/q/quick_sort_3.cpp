/* Portable three-way quicksort using the final value as pivot. */
#include <cstddef>
#include <cstdint>

static void quick_sort_3_range(std::int64_t *values, std::size_t low_value, std::size_t high_value) noexcept
{
    std::size_t low = low_value;
    std::size_t high = high_value;
    while (high - low > 1) {
        const std::int64_t pivot = values[high - 1];
        std::size_t less = low;
        std::size_t scan = low;
        std::size_t greater = high;
        while (scan < greater) {
            if (values[scan] < pivot) {
                const std::int64_t temporary = values[less];
                values[less] = values[scan];
                values[scan] = temporary;
                ++less;
                ++scan;
            } else if (values[scan] > pivot) {
                --greater;
                const std::int64_t temporary = values[scan];
                values[scan] = values[greater];
                values[greater] = temporary;
            } else {
                ++scan;
            }
        }
        if (less - low < high - greater) {
            quick_sort_3_range(values, low, less);
            low = greater;
        } else {
            quick_sort_3_range(values, greater, high);
            high = less;
        }
    }
}

extern "C" void quick_sort_3(std::int64_t *values, std::size_t length) noexcept
{
    if (length > 1) quick_sort_3_range(values, 0, length);
}
