/* Dark sort: counting sort for nonnegative keys in [0, 128]. */
#include <cstddef>
#include <cstdint>

extern "C" void dark_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length < 2) return;
    std::int64_t maximum = values[0];
    for (std::size_t i = 1; i < length; ++i) if (values[i] > maximum) maximum = values[i];
    std::int64_t counts[129] = {};
    for (std::size_t i = 0; i < length; ++i) ++counts[static_cast<std::size_t>(values[i])];
    std::size_t output = 0;
    for (std::int64_t value = 0; value <= maximum; ++value)
        while (counts[static_cast<std::size_t>(value)]-- > 0) values[output++] = value;
}
