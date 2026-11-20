/* Bounded Olver cutoff and backward recurrence over binary64 coefficients. */
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_parseable_input_length = 53;
constexpr int max_nmax = 12;

bool exact_integer(double value, int low, int high, int& result) noexcept {
    if (!std::isfinite(value) || value < low || value > high || std::trunc(value) != value) return false;
    result = static_cast<int>(value);
    return true;
}

bool validate(const double* input, std::size_t length, int& m, int& nmax) noexcept {
    if (input == nullptr || length < 8 || length > max_parseable_input_length) return false;
    for (std::size_t i = 0; i < length; ++i) if (!std::isfinite(input[i])) return false;
    if (!exact_integer(input[0], 1, 8, m) || !exact_integer(input[1], 1, max_nmax, nmax)) return false;
    if (m > nmax || length != 4 + 4 * static_cast<std::size_t>(nmax)) return false;
    if (input[2] < 0x1p-40 || input[2] > 0.5 || std::abs(input[3]) > 16.0) return false;
    for (int i = 0; i < nmax; ++i) {
        if (std::abs(input[4 + i]) < 0.0625 || std::abs(input[4 + i]) > 16.0 ||
            std::abs(input[4 + nmax + i]) > 16.0 ||
            std::abs(input[4 + 2 * nmax + i]) > 16.0 ||
            std::abs(input[4 + 3 * nmax + i]) > 16.0) return false;
    }
    return true;
}
}

extern "C" std::int64_t olver_backward_recurrence_boundary_value(
    const double* input, std::size_t input_length, double* output,
    std::size_t output_capacity) noexcept {
    int m, nmax;
    if (!validate(input, input_length, m, nmax)) return -1;
    const auto required = static_cast<std::size_t>(m + 2);
    if (output == nullptr || output_capacity < required) return -2;

    double p[14]{};
    double e[13]{};
    double w[13]{};
    p[1] = 1.0;
    e[0] = input[3];
    for (int n = 1; n <= m; ++n) {
        const double a = input[4 + n - 1];
        const double b = input[4 + nmax + n - 1];
        const double c = input[4 + 2 * nmax + n - 1];
        const double d = input[4 + 3 * nmax + n - 1];
        p[n + 1] = (b * p[n] - c * p[n - 1]) / a;
        e[n] = (c * e[n - 1] - d * p[n]) / a;
        if (!std::isfinite(p[n + 1]) || !std::isfinite(e[n])) return -3;
    }
    for (int n = 1; n <= m; ++n) {
        const double product = p[n] * p[n + 1];
        if (product == 0.0 || !std::isfinite(product) || !std::isfinite(e[n] / product)) return -3;
    }
    double minimum = std::abs(e[1] / (p[1] * p[2]));
    for (int n = 2; n <= m; ++n) {
        const double ratio = std::abs(e[n] / (p[n] * p[n + 1]));
        if (ratio < minimum) minimum = ratio;
    }
    const double threshold = input[2] * minimum;
    int endpoint = 0;
    for (int n = m; n <= nmax; ++n) {
        if (n > m) {
            const double a = input[4 + n - 1];
            const double b = input[4 + nmax + n - 1];
            const double c = input[4 + 2 * nmax + n - 1];
            const double d = input[4 + 3 * nmax + n - 1];
            p[n + 1] = (b * p[n] - c * p[n - 1]) / a;
            e[n] = (c * e[n - 1] - d * p[n]) / a;
            if (!std::isfinite(p[n + 1]) || !std::isfinite(e[n])) return -3;
        }
        const double product = p[n] * p[n + 1];
        if (product == 0.0 || !std::isfinite(product)) return -3;
        const double ratio = std::abs(e[n] / product);
        if (!std::isfinite(ratio)) return -3;
        if (ratio <= threshold) { endpoint = n; break; }
    }
    if (endpoint == 0) return -3;
    w[endpoint] = 0.0;
    for (int n = endpoint - 1; n >= 0; --n) {
        w[n] = (p[n] * w[n + 1] + e[n]) / p[n + 1];
        if (!std::isfinite(w[n])) return -3;
    }
    output[0] = static_cast<double>(endpoint);
    for (int i = 0; i <= m; ++i) output[i + 1] = w[i];
    return static_cast<std::int64_t>(required);
}
