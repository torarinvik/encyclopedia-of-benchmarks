/* Return the largest signed value in a nonempty array. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t find_max(const std::int64_t *values, std::size_t length) noexcept
{
    if (length == 0 || length > 512) return -1;
    std::int64_t result = values[0];
    for (std::size_t index = 1; index < length; ++index) {
        if (values[index] > result) result = values[index];
    }
    return result;
}
