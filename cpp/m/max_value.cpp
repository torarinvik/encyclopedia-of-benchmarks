#include <cstdint>
#include <limits>

extern "C" std::int64_t max_value(std::int64_t a, std::int64_t b) noexcept {
    if (a < std::numeric_limits<std::int32_t>::min() || a > std::numeric_limits<std::int32_t>::max() ||
        b < std::numeric_limits<std::int32_t>::min() || b > std::numeric_limits<std::int32_t>::max()) return -1;
    return a >= b ? a : b;
}
