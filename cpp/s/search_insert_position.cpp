#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" std::int64_t search_insert_position(const std::int64_t *input, std::size_t length) {
    if (length < 1 || length > 257 || input == nullptr) return -1;
    const std::int64_t target = input[0];
    if (target < std::numeric_limits<std::int32_t>::min() ||
        target > std::numeric_limits<std::int32_t>::max()) return -1;
    for (std::size_t index = 1; index < length; ++index) {
        if (input[index] < std::numeric_limits<std::int32_t>::min() ||
            input[index] > std::numeric_limits<std::int32_t>::max()) return -1;
        if (index > 1 && input[index - 1] >= input[index]) return -1;
    }
    std::size_t low = 0;
    std::size_t high = length - 1;
    while (low < high) {
        const std::size_t middle = low + (high - low) / 2;
        if (input[middle + 1] < target) low = middle + 1;
        else high = middle;
    }
    return static_cast<std::int64_t>(low);
}
