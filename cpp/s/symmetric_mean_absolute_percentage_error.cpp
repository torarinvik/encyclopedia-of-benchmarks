#include <cmath>
#include <cstddef>
#include <cstdint>
#define INVALID_RESULT (-1.0e300)
#define SCALE 1000000.0
extern "C" double symmetric_mean_absolute_percentage_error(const std::int64_t *values, std::size_t length) {
    if (values == NULL || length < 1) return INVALID_RESULT;
    const std::int64_t n = values[0];
    if (n < 1 || n > 64 || length != 1 + 2 * (std::size_t)n) return INVALID_RESULT;
    for (std::size_t i = 0; i < 2 * (std::size_t)n; i++) if (values[1 + i] < -1000000 || values[1 + i] > 1000000) return INVALID_RESULT;
    double total = 0.0;
    for (std::size_t i = 0; i < (std::size_t)n; i++) { double t = (double)values[1+i] / SCALE, p = (double)values[1+(std::size_t)n+i] / SCALE;
        double d = (std::fabs(t) + std::fabs(p)) / 2.0; if (d == 0.0) d = 1e-15; total += std::fabs(t - p) / d;
    }
    return total / (double)n;
}
