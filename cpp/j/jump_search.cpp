/* Independent portable implementation of TheAlgorithms/C-Plus-Plus jump search. */
#include <cstddef>
#include <cstdint>

static std::size_t integer_sqrt(std::size_t value) noexcept
{
    if (value < 2) return value;
    std::size_t low = 1;
    std::size_t high = value / 2 + 1;
    std::size_t result = 1;
    while (low <= high) {
        const std::size_t middle = low + (high - low) / 2;
        if (middle <= value / middle) {
            result = middle;
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    return result;
}

extern "C" std::int64_t jump_search(const std::int64_t *values,
                                    std::size_t length,
                                    std::int64_t target) noexcept
{
    if (length == 0) return -1;
    const std::size_t step = integer_sqrt(length);
    std::size_t block_start = 0;
    std::size_t block_end = step < length ? step : length;

    while (values[block_end - 1] < target) {
        if (block_end == length) return -1;
        block_start = block_end;
        block_end = step > length - block_end ? length : block_end + step;
    }

    for (std::size_t index = block_start; index < block_end; ++index) {
        if (values[index] == target) return static_cast<std::int64_t>(index);
        if (values[index] > target) return -1;
    }
    return -1;
}
