#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 30;
constexpr std::size_t max_tsteps = 20;
}

extern "C" std::int64_t jacobi_1d(const double *input, std::size_t length,
                                   double *output, std::size_t capacity) {
    if (input == nullptr || length != 2 || !std::isfinite(input[0]) || !std::isfinite(input[1]) ||
        std::trunc(input[0]) != input[0] || std::trunc(input[1]) != input[1] ||
        input[0] < 1.0 || input[0] > max_n || input[1] < 0.0 || input[1] > max_tsteps) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    const std::size_t tsteps = static_cast<std::size_t>(input[1]);
    if (output == nullptr || capacity < n) return -2;

    double a[max_n]{}, b[max_n]{};
    for (std::size_t i = 0; i < n; ++i) {
        a[i] = (static_cast<double>(i) + 2.0) / static_cast<double>(n);
        b[i] = (static_cast<double>(i) + 3.0) / static_cast<double>(n);
    }
    for (std::size_t t = 0; t < tsteps; ++t) {
        for (std::size_t i = 1; i + 1 < n; ++i) b[i] = 0.33333 * (a[i - 1] + a[i] + a[i + 1]);
        for (std::size_t i = 1; i + 1 < n; ++i) a[i] = 0.33333 * (b[i - 1] + b[i] + b[i + 1]);
    }
    for (std::size_t i = 0; i < n; ++i) output[i] = a[i];
    return static_cast<std::int64_t>(n);
}
