#include <cstdint>

namespace { constexpr std::int64_t MAX_LIMIT = 1000; }

extern "C" std::int64_t problem120(std::int64_t limit) noexcept
{
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    std::int64_t total = 0;
    for (std::int64_t a = 3; a <= limit; ++a) total += 2 * a * ((a - 1) / 2);
    return total;
}
