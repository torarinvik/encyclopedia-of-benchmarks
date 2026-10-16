/* Portable sentinel search implementation following the pinned PHP and TypeScript algorithm. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t sentinel_search(std::int64_t *values,
                                                std::size_t length,
                                                std::int64_t target) noexcept
{
    if (length == 0) {
        return -1;
    }

    const std::size_t last_index = length - 1;
    const std::int64_t saved_last = values[last_index];
    if (saved_last == target) {
        return static_cast<std::int64_t>(last_index);
    }

    values[last_index] = target;
    std::size_t index = 0;
    while (values[index] != target) {
        ++index;
    }
    values[last_index] = saved_last;

    return index == last_index ? -1 : static_cast<std::int64_t>(index);
}
