#include <cstdint>

extern "C" std::int64_t problem138(std::int64_t count) noexcept
{
    if (count > 14) return -1;
    if (count <= 0) return 0;
    std::int64_t m = 2, l = 1, total = 0;
    for (std::int64_t i = 0; i < count; ++i) {
        const auto next_m = 9 * m + 20 * l;
        const auto next_l = 4 * m + 9 * l;
        m = next_m;
        l = next_l;
        total += l;
    }
    return total;
}
