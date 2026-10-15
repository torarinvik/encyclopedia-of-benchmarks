#include <cmath>
#include <cstdint>
#include <limits>

extern "C" std::int64_t binary_length(std::int64_t value) noexcept
{
    if (value <= 0 || value > std::numeric_limits<std::int32_t>::max()) return -1;
    return static_cast<std::int64_t>(std::floor(std::log2(static_cast<double>(value))) + 1.0);
}
