/* Count right triangles formed by unordered pairs of grid points and the origin. */
#include <cstdint>

namespace {
constexpr std::int64_t MAX_LIMIT = 50;
}

extern "C" std::int64_t problem91(std::int64_t limit) noexcept
{
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    std::int64_t count = 0;
    for (std::int64_t x1 = 0; x1 <= limit; ++x1) {
        for (std::int64_t y1 = 0; y1 <= limit; ++y1) {
            for (std::int64_t x2 = x1; x2 <= limit; ++x2) {
                const std::int64_t first_y2 = x2 == x1 ? y1 + 1 : 0;
                for (std::int64_t y2 = first_y2; y2 <= limit; ++y2) {
                    if ((x1 == 0 && y1 == 0) || (x2 == 0 && y2 == 0)) continue;
                    const auto op = x1 * x1 + y1 * y1;
                    const auto oq = x2 * x2 + y2 * y2;
                    const auto dx = x1 - x2;
                    const auto dy = y1 - y2;
                    const auto pq = dx * dx + dy * dy;
                    if (op + oq == pq || op + pq == oq || oq + pq == op) ++count;
                }
            }
        }
    }
    return count;
}
