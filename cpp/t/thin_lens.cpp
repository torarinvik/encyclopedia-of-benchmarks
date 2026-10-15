/* Bounded selector wrapper for the Java thin-lens operations. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
}

extern "C" double thin_lens(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length != 3) return invalid_result;
    const auto operation = values[0], a = values[1], b = values[2];
    if (a < -1000 || a > 1000 || b < -1000 || b > 1000) return invalid_result;
    if (operation == 0) {
        if (a == 0 || b == 0 || a == b) return invalid_result;
        const double f = static_cast<double>(a), u = static_cast<double>(b);
        return 1.0 / ((1.0 / f) - (1.0 / u));
    }
    if (operation == 1) {
        if (b == 0) return invalid_result;
        return static_cast<double>(a) / static_cast<double>(b);
    }
    if (operation == 2) {
        if (b != 0) return invalid_result;
        return a > 0 ? 1.0 : 0.0;
    }
    return invalid_result;
}
