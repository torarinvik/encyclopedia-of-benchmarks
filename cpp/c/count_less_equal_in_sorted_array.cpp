#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" std::int64_t count_less_equal_in_sorted_array(const std::int64_t *input,
                                                          std::size_t length)
{
    if (input == nullptr || length < 1 || length > 513) return -1;
    const std::int64_t key = input[0];
    if (key < std::numeric_limits<std::int32_t>::min() ||
        key > std::numeric_limits<std::int32_t>::max()) return -1;
    for (std::size_t index = 1; index < length; ++index) {
        const std::int64_t value = input[index];
        if (value < std::numeric_limits<std::int32_t>::min() ||
            value > std::numeric_limits<std::int32_t>::max()) return -1;
        if (index > 1 && input[index - 1] > value) return -1;
    }

    std::int64_t left = 1;
    std::int64_t right = static_cast<std::int64_t>(length) - 1;
    std::int64_t count = 0;
    while (left <= right) {
        const std::int64_t middle = left + (right - left) / 2;
        if (input[middle] > key) right = middle - 1;
        else {
            count = middle;
            left = middle + 1;
        }
    }
    return count;
}
