/* Stable bottom-up TimSort-style merge sort with reusable caller scratch. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t TIM_SORT_RUN = 32;

void insertion_sort_run(std::int64_t *values, std::size_t low, std::size_t high) noexcept
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

void merge_runs(std::int64_t *values, std::int64_t *scratch,
                std::size_t left, std::size_t middle, std::size_t right) noexcept
{
    for (std::size_t index = left; index < right; ++index) scratch[index] = values[index];
    std::size_t first = left;
    std::size_t second = middle;
    for (std::size_t output = left; output < right; ++output) {
        if (first == middle) {
            values[output] = scratch[second++];
        } else if (second == right || scratch[first] <= scratch[second]) {
            values[output] = scratch[first++];
        } else {
            values[output] = scratch[second++];
        }
    }
}
}

extern "C" void tim_sort(std::int64_t *values, std::int64_t *scratch,
                         std::size_t length) noexcept
{
    if (length < 2) return;
    std::size_t start = 0;
    while (start < length) {
        const std::size_t remaining = length - start;
        const std::size_t end = remaining < TIM_SORT_RUN ? length : start + TIM_SORT_RUN;
        insertion_sort_run(values, start, end);
        start = end;
    }

    std::size_t width = TIM_SORT_RUN;
    while (width < length) {
        std::size_t left = 0;
        while (left < length) {
            const std::size_t middle = left + (width < length - left ? width : length - left);
            const std::size_t right = middle + (width < length - middle ? width : length - middle);
            if (middle < right) merge_runs(values, scratch, left, middle, right);
            left = right;
        }
        if (width >= length - width) break;
        width *= 2;
    }
}
