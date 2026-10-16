#include <cstddef>
#include <cstdint>

namespace {
std::uint64_t bst_shape(std::size_t start, std::size_t end, std::size_t heap_index)
{
    if (start >= end) return 0;
    const auto middle = start + (end - start - 1) / 2;
    return (std::uint64_t{1} << heap_index)
         | bst_shape(start, middle, 2 * heap_index + 1)
         | bst_shape(middle + 1, end, 2 * heap_index + 2);
}
}

extern "C" std::int64_t bst_from_sorted_array(const std::int64_t *values,
                                                std::size_t length) noexcept
{
    if (length > 15 || (length != 0 && values == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < INT32_MIN || values[index] > INT32_MAX) return -1;
        if (index != 0 && values[index - 1] >= values[index]) return -1;
    }
    return static_cast<std::int64_t>(bst_shape(0, length, 0));
}
