#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t kahan_summation(const double *values, std::size_t length,
                                        double *output, std::size_t capacity) {
    if (values == nullptr || length > 256) return -1;
    for (std::size_t i = 0; i < length; ++i) {
        if (!std::isfinite(values[i]) || std::abs(values[i]) > 1.0e100) return -1;
    }
    if (output == nullptr || capacity < 1) return -2;

    double sum = 0.0;
    double correction = 0.0;
    for (std::size_t i = 0; i < length; ++i) {
        const double adjusted = values[i] - correction;
        const double next = sum + adjusted;
        correction = (next - sum) - adjusted;
        sum = next;
    }
    output[0] = sum;
    return 1;
}
