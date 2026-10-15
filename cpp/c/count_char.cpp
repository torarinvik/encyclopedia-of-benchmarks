#include <cstddef>
#include <cstdint>

extern "C" std::int64_t count_char(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > 4096 || (length != 0 && values == nullptr)) return -1;
    std::int64_t count = 0;
    for (std::size_t i = 0; i < length; ++i) {
        const std::int64_t code = values[i];
        if (code < 0 || code > 127) return -1;
        if (code != 9 && code != 10 && code != 11 && code != 12 && code != 13 && code != 32) ++count;
    }
    return count;
}
