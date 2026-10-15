#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 1024;

void adaptive_merge_sort_range(std::int64_t *values, std::int64_t *scratch,
                        std::size_t low, std::size_t high)
{
    if (high - low <= 1) return;
    const std::size_t middle = low + (high - low) / 2;
    adaptive_merge_sort_range(values, scratch, low, middle);
    adaptive_merge_sort_range(values, scratch, middle, high);
    if (values[middle - 1] <= values[middle]) return;

    std::size_t left = low;
    std::size_t right = middle;
    std::size_t output = low;
    while (left < middle && right < high) {
        scratch[output++] = values[left] <= values[right]
            ? values[left++] : values[right++];
    }
    while (left < middle) scratch[output++] = values[left++];
    while (right < high) scratch[output++] = values[right++];
    for (std::size_t index = low; index < high; ++index) values[index] = scratch[index];
}
}

extern "C" void adaptive_merge_sort(std::int64_t *values, std::size_t length)
{
    if (length > max_values) return;
    std::int64_t scratch[max_values];
    adaptive_merge_sort_range(values, scratch, 0, length);
}
