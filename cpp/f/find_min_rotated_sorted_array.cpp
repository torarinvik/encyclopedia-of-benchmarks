#include <cstddef>
#include <cstdint>

extern "C" std::int64_t find_min_rotated_sorted_array(const std::int64_t *values, std::size_t length) {
    if (length < 1 || length > 256 || values == nullptr) return -1;
    std::size_t low = 0;
    std::size_t high = length - 1;
    while (low < high) {
        const std::size_t middle = low + (high - low) / 2;
        if (values[middle] <= values[high]) high = middle;
        else low = middle + 1;
    }
    return values[low];
}
