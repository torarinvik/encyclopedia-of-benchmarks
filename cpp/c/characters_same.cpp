#include <cstddef>
#include <cstdint>

extern "C" std::int64_t characters_same(const std::int64_t *values, std::size_t length)
{
    if (length > 256 || (length != 0 && values == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > 127) return -1;
    if (length == 0) return 1;
    const std::int64_t first = values[0];
    for (std::size_t index = 1; index < length; ++index)
        if (values[index] != first) return 0;
    return 1;
}
