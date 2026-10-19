#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 40;
}

extern "C" std::int64_t trisolv(const double *input, std::size_t length,
                                 double *output, std::size_t capacity) {
    if (input == nullptr || length != 1 || !std::isfinite(input[0]) ||
        std::trunc(input[0]) != input[0] || input[0] < 1.0 || input[0] > max_n) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (output == nullptr || capacity < n) return -2;

    double lower[max_n][max_n]{};
    double b[max_n]{};
    double x[max_n]{};
    for (std::size_t i = 0; i < n; ++i) {
        b[i] = static_cast<double>(i);
        for (std::size_t j = 0; j <= i; ++j)
            lower[i][j] = static_cast<double>(i + n - j + 1) * 2.0 / static_cast<double>(n);
    }
    for (std::size_t i = 0; i < n; ++i) {
        x[i] = b[i];
        for (std::size_t j = 0; j < i; ++j) x[i] -= lower[i][j] * x[j];
        x[i] /= lower[i][i];
    }
    for (std::size_t i = 0; i < n; ++i) output[i] = x[i];
    return static_cast<std::int64_t>(n);
}
