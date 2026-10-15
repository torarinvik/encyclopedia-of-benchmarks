/* Iterative Lomuto quicksort using the final value as the pivot. */
#include <cstddef>
#include <cstdint>
#include <climits>

static std::size_t quick_sort_iterative_partition(std::int64_t *values,
                                                  std::size_t low,
                                                  std::size_t high) noexcept
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

extern "C" void quick_sort_iterative(std::int64_t *values, std::size_t length) noexcept
{
    if (length < 2) return;

    constexpr std::size_t RANGE_STACK_CAPACITY = sizeof(std::size_t) * CHAR_BIT;
    std::size_t stack_low[RANGE_STACK_CAPACITY];
    std::size_t stack_high[RANGE_STACK_CAPACITY];
    std::size_t stack_size = 0;
    std::size_t low = 0;
    std::size_t high = length;

    for (;;) {
        while (high - low > 1) {
            const std::size_t pivot = quick_sort_iterative_partition(values, low, high);
            const std::size_t left_size = pivot - low;
            const std::size_t right_size = high - pivot - 1;
            if (left_size < right_size) {
                if (right_size > 1) {
                    stack_low[stack_size] = pivot + 1;
                    stack_high[stack_size] = high;
                    ++stack_size;
                }
                high = pivot;
            } else {
                if (left_size > 1) {
                    stack_low[stack_size] = low;
                    stack_high[stack_size] = pivot;
                    ++stack_size;
                }
                low = pivot + 1;
            }
        }
        if (stack_size == 0) break;
        --stack_size;
        low = stack_low[stack_size];
        high = stack_high[stack_size];
    }
}
