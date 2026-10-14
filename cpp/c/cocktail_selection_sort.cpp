#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 1024;
}

extern "C" void cocktail_selection_sort(std::int64_t *values, std::size_t length)
{
    if (length > max_values) {
        return;
    }

    std::size_t low = 0;
    std::size_t high = length;
    while (low < high && high - low > 1) {
        std::size_t minimum_index = low;
        std::size_t maximum_index = low;
        for (std::size_t index = low + 1; index < high; ++index) {
            if (values[index] < values[minimum_index]) {
                minimum_index = index;
            }
            if (values[index] > values[maximum_index]) {
                maximum_index = index;
            }
        }

        const std::int64_t minimum = values[minimum_index];
        values[minimum_index] = values[low];
        values[low] = minimum;
        if (maximum_index == low) {
            maximum_index = minimum_index;
        }
        const std::int64_t maximum = values[maximum_index];
        values[maximum_index] = values[high - 1];
        values[high - 1] = maximum;
        ++low;
        --high;
    }
}
