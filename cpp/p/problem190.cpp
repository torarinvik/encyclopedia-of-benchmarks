#include <cmath>
#include <cstdint>

namespace { constexpr std::int64_t MAX_N = 15; }

extern "C" std::int64_t problem190(std::int64_t n) noexcept
{
    if (n < 0 || n > MAX_N) return -1;
    std::int64_t total = 0;
    for (std::int64_t m = 2; m <= n; ++m) {
        const double x1 = 2.0 / static_cast<double>(m + 1);
        double product = 1.0;
        for (std::int64_t i = 1; i <= m; ++i) {
            const double xi = static_cast<double>(i) * x1;
            product *= std::pow(xi, static_cast<double>(i));
        }
        total += static_cast<std::int64_t>(product);
    }
    return total;
}
