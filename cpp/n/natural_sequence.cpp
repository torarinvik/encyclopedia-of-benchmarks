#include <cstdint>
#include <limits>

extern "C" std::int64_t natural_sequence(std::int64_t index) noexcept
{
    if (index < 0 || index == std::numeric_limits<std::int64_t>::max()) return -1;
    return index + 1;
}
