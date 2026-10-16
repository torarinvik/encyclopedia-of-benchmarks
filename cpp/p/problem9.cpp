#include <cstdint>

extern "C" std::int64_t problem9(std::int64_t total) noexcept
{
    if (total < 3 || total > 1000) return -1;
    for (std::int64_t a = 1; a <= total / 3; ++a) {
        for (std::int64_t b = a + 1; 2 * b < total - a; ++b) {
            const std::int64_t c = total - a - b;
            if (a * a + b * b == c * c) return a * b * c;
        }
    }
    return -1;
}
