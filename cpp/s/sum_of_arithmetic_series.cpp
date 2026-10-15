#include <cstddef>
#include <cstdint>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double sum_of_arithmetic_series(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length != 3) return INVALID_RESULT;
    const std::int64_t a = packed[0];
    const std::int64_t d = packed[1];
    const std::int64_t n = packed[2];
    if (a < -1000 || a > 1000 || d < -1000 || d > 1000 || n < 1 || n > 1000) return INVALID_RESULT;
    const std::int64_t result = n * (2 * a + (n - 1) * d) / 2;
    return static_cast<double>(result);
}
