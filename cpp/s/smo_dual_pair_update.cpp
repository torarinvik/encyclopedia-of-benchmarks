#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 8;
constexpr int max_d = 3;
constexpr std::size_t max_input = 47;

bool field(double x, int low, int high, int& value) noexcept {
    if (!std::isfinite(x) || x < low || x > high || std::trunc(x) != x) return false;
    value = static_cast<int>(x);
    return true;
}

double dot(const double (&a)[max_d], const double (&b)[max_d], int d) noexcept {
    double result = 0.0;
    for (int k = 0; k < d; ++k) result += a[k] * b[k];
    return result;
}

double objective(const double (&a)[max_n], const int (&y)[max_n],
                 const double (&x)[max_n][max_d], int n, int d) noexcept {
    double result = 0.0;
    for (int p = 0; p < n; ++p) result += a[p];
    for (int p = 0; p < n; ++p)
        for (int q = 0; q < n; ++q)
            result -= 0.5 * a[p] * a[q] * y[p] * y[q] * dot(x[p], x[q], d);
    return result;
}
}

extern "C" std::int64_t smo_dual_pair_update(
    const double* input, std::size_t input_length, double* output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 6 || input_length > max_input) return -1;
    int n, d, c_milli, b_milli;
    if (!field(input[0], 2, max_n, n) || !field(input[1], 1, max_d, d) ||
        !field(input[2], 1, 5000, c_milli) ||
        !field(input[3], -1000000, 1000000, b_milli) ||
        input_length != static_cast<std::size_t>(6 + 2 * n + n * d)) return -1;

    int y[max_n]{};
    double alpha[max_n]{};
    double x[max_n][max_d]{};
    bool negative = false, positive = false;
    int equality = 0;
    std::size_t at = 4;
    for (int k = 0; k < n; ++k) {
        if (!field(input[at++], -1, 1, y[k]) || y[k] == 0) return -1;
        negative |= y[k] < 0;
        positive |= y[k] > 0;
    }
    for (int k = 0; k < n; ++k) {
        int value;
        if (!field(input[at++], 0, c_milli, value)) return -1;
        alpha[k] = static_cast<double>(value) / 1000.0;
        equality += y[k] * value;
    }
    if (!negative || !positive || equality != 0) return -1;
    for (int k = 0; k < n; ++k)
        for (int r = 0; r < d; ++r) {
            int value;
            if (!field(input[at++], -32, 32, value)) return -1;
            x[k][r] = value;
        }
    int i, j;
    if (!field(input[at++], 0, n - 1, i) || !field(input[at], 0, n - 1, j) || i == j)
        return -1;
    if (output == nullptr || output_capacity < static_cast<std::size_t>(n + 1)) return -2;

    const double c_value = static_cast<double>(c_milli) / 1000.0;
    const double bias = static_cast<double>(b_milli) / 1000.0;
    const int yi = y[i], yj = y[j], sign = yi * yj;
    const double old_i = alpha[i], old_j = alpha[j];
    const double kii = dot(x[i], x[i], d), kjj = dot(x[j], x[j], d);
    const double kij = dot(x[i], x[j], d);
    double error_i = bias - yi, error_j = bias - yj;
    for (int k = 0; k < n; ++k) {
        error_i += alpha[k] * y[k] * dot(x[k], x[i], d);
        error_j += alpha[k] * y[k] * dot(x[k], x[j], d);
    }
    const double low = yi != yj ? std::max(0.0, old_j - old_i)
                                : std::max(0.0, old_i + old_j - c_value);
    const double high = yi != yj ? std::min(c_value, c_value + old_j - old_i)
                                 : std::min(c_value, old_i + old_j);
    const double eta = 2.0 * kij - kii - kjj;
    double new_j;
    if (eta < 0.0) {
        new_j = std::clamp(old_j - yj * (error_i - error_j) / eta, low, high);
    } else {
        double candidate[max_n];
        std::copy_n(alpha, n, candidate);
        candidate[i] = old_i + sign * (old_j - low);
        candidate[j] = low;
        const double low_score = objective(candidate, y, x, n, d);
        candidate[i] = old_i + sign * (old_j - high);
        candidate[j] = high;
        const double high_score = objective(candidate, y, x, n, d);
        new_j = high_score > low_score ? high : low;
    }
    const double new_i = old_i + sign * (old_j - new_j);
    const double delta_i = new_i - old_i, delta_j = new_j - old_j;
    const double bias_i = bias - error_i - yi * delta_i * kii - yj * delta_j * kij;
    const double bias_j = bias - error_j - yi * delta_i * kij - yj * delta_j * kjj;
    const double new_bias = (new_i > 0.0 && new_i < c_value) ? bias_i :
                            (new_j > 0.0 && new_j < c_value) ? bias_j :
                            0.5 * (bias_i + bias_j);
    alpha[i] = new_i;
    alpha[j] = new_j;
    std::copy_n(alpha, n, output);
    output[n] = new_bias;
    return n + 1;
}
