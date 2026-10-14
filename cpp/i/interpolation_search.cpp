/* Independent portable implementation of TheAlgorithms/C-Plus-Plus interpolation search. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t interpolation_search(const std::int64_t *values,
                                              std::size_t length,
                                              std::int64_t target) noexcept
{
    if (length == 0) return -1;
    std::size_t low = 0;
    std::size_t high = length - 1;

    while (low <= high) {
        const std::int64_t low_value = values[low];
        const std::int64_t high_value = values[high];
        if (target < low_value || target > high_value) return -1;
        if (low_value == high_value) return low_value == target ? static_cast<std::int64_t>(low) : -1;

        const std::int64_t numerator = (target - low_value) * static_cast<std::int64_t>(high - low);
        const std::int64_t denominator = high_value - low_value;
        const std::size_t position = low + static_cast<std::size_t>(numerator / denominator);
        const std::int64_t value = values[position];
        if (value == target) return static_cast<std::int64_t>(position);
        if (value < target) {
            low = position + 1;
        } else {
            if (position == 0) return -1;
            high = position - 1;
        }
    }
    return -1;
}
