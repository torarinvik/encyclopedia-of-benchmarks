#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 40;
}

extern "C" std::int64_t durbin(const double *input, std::size_t length,
                                double *output, std::size_t capacity) {
    if (input == nullptr || length != 1 || !std::isfinite(input[0]) ||
        std::trunc(input[0]) != input[0] || input[0] < 1.0 || input[0] > max_n) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    if (output == nullptr || capacity < n) return -2;

    double r[max_n]{}, y[max_n]{}, z[max_n]{};
    for (std::size_t i = 0; i < n; ++i) r[i] = static_cast<double>(n + 1 - i);
    y[0] = -r[0];
    double beta = 1.0;
    double alpha = -r[0];
    for (std::size_t k = 1; k < n; ++k) {
        beta = (1.0 - alpha * alpha) * beta;
        double sum = 0.0;
        for (std::size_t i = 0; i < k; ++i) sum += r[k - i - 1] * y[i];
        alpha = -(r[k] + sum) / beta;
        for (std::size_t i = 0; i < k; ++i) z[i] = y[i] + alpha * y[k - i - 1];
        for (std::size_t i = 0; i < k; ++i) y[i] = z[i];
        y[k] = alpha;
    }
    for (std::size_t i = 0; i < n; ++i) output[i] = y[i];
    return static_cast<std::int64_t>(n);
}
