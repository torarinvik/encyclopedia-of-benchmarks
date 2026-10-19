#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 30;
constexpr std::size_t max_tsteps = 20;
}

extern "C" std::int64_t jacobi_2d(const double *input, std::size_t length,
                                   double *output, std::size_t capacity) {
    if (input == nullptr || length != 2 || !std::isfinite(input[0]) || !std::isfinite(input[1]) ||
        std::trunc(input[0]) != input[0] || std::trunc(input[1]) != input[1] ||
        input[0] < 1.0 || input[0] > max_n || input[1] < 0.0 || input[1] > max_tsteps) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    const std::size_t tsteps = static_cast<std::size_t>(input[1]);
    const std::size_t count = n * n;
    if (output == nullptr || capacity < count) return -2;

    double a[max_n][max_n]{}, b[max_n][max_n]{};
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = 0; j < n; ++j) {
            a[i][j] = (static_cast<double>(i) * static_cast<double>(j + 2) + 2.0) / static_cast<double>(n);
            b[i][j] = (static_cast<double>(i) * static_cast<double>(j + 3) + 3.0) / static_cast<double>(n);
        }
    }
    for (std::size_t t = 0; t < tsteps; ++t) {
        for (std::size_t i = 1; i + 1 < n; ++i) {
            for (std::size_t j = 1; j + 1 < n; ++j)
                b[i][j] = 0.2 * (a[i][j] + a[i][j - 1] + a[i][j + 1] + a[i + 1][j] + a[i - 1][j]);
        }
        for (std::size_t i = 1; i + 1 < n; ++i) {
            for (std::size_t j = 1; j + 1 < n; ++j)
                a[i][j] = 0.2 * (b[i][j] + b[i][j - 1] + b[i][j + 1] + b[i + 1][j] + b[i - 1][j]);
        }
    }
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < n; ++j) output[i * n + j] = a[i][j];
    return static_cast<std::int64_t>(count);
}
