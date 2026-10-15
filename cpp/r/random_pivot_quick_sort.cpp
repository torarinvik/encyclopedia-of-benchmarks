/* Reproducible randomized-pivot Lomuto quicksort. */
#include <climits>
#include <cstddef>
#include <cstdint>

static std::uint64_t random_pivot_quick_sort_next31(std::uint64_t *state) noexcept
{
    *state = (*state * UINT64_C(48271)) % UINT64_C(2147483647);
    return *state;
}

static std::uint64_t random_pivot_quick_sort_next(std::uint64_t *state) noexcept
{
    const std::uint64_t high = random_pivot_quick_sort_next31(state);
    const std::uint64_t low = random_pivot_quick_sort_next31(state);
    return high * UINT64_C(2147483647) + low;
}

static std::size_t random_pivot_quick_sort_partition(std::int64_t *values,
                                                     std::size_t low,
                                                     std::size_t high,
                                                     std::uint64_t *state) noexcept
{
    const std::size_t width = high - low;
    const std::size_t pivot_index = low + static_cast<std::size_t>(random_pivot_quick_sort_next(state) % width);
    const std::int64_t pivot_value = values[pivot_index];
    const std::int64_t pivot_slot = values[high - 1];
    values[high - 1] = pivot_value;
    values[pivot_index] = pivot_slot;

    std::size_t boundary = low;
    for (std::size_t scan = low; scan < high - 1; ++scan) {
        if (values[scan] < pivot_value) {
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

extern "C" void random_pivot_quick_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length < 2) return;
    constexpr std::size_t RANGE_STACK_CAPACITY = sizeof(std::size_t) * CHAR_BIT;
    std::size_t stack_low[RANGE_STACK_CAPACITY];
    std::size_t stack_high[RANGE_STACK_CAPACITY];
    std::size_t stack_size = 0;
    std::size_t low = 0;
    std::size_t high = length;
    std::uint64_t random_state = 1;
    for (;;) {
        while (high - low > 1) {
            const std::size_t pivot = random_pivot_quick_sort_partition(values, low, high, &random_state);
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
