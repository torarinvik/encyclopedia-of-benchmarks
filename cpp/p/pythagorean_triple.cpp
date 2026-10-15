// Check three signed integers with Java-compatible int-safe bounds.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t pythagorean_triple(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length != 3) return -1;
    std::int64_t a = values[0], b = values[1], c = values[2];
    if (a < -32768 || a > 32767 || b < -32768 || b > 32767 || c < -32768 || c > 32767)
        return -1;
    if (a <= 0 || b <= 0 || c <= 0) return 0;
    if (a > b) { const auto t = a; a = b; b = t; }
    if (b > c) { const auto t = b; b = c; c = t; }
    if (a > b) { const auto t = a; a = b; b = t; }
    return a * a + b * b == c * c ? 1 : 0;
}
