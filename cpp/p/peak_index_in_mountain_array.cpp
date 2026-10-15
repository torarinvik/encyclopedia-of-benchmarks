// Find the peak of a strict mountain array with binary search.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_array_length = 100000;
}

extern "C" std::int64_t peak_index_in_mountain_array(const std::int64_t *values,
                                                     std::size_t length) noexcept {
    if (values == nullptr || length < 3 || length > max_array_length) return -1;
    std::size_t low = 0, high = length - 1;
    while (low < high) {
        const std::size_t middle = low + (high - low) / 2;
        if (values[middle] < values[middle + 1]) low = middle + 1;
        else high = middle;
    }
    if (low == 0 || low + 1 == length) return -1;
    return static_cast<std::int64_t>(low);
}
