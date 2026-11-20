#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
bool exact_integer(double value, int low, int high, int &decoded) {
    if (!std::isfinite(value) || value < low || value > high || std::trunc(value) != value) return false;
    decoded = static_cast<int>(value);
    return true;
}
}

extern "C" std::int64_t lanczos_symmetric_tridiagonalization(
    const double *input, std::size_t input_length, double *output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 3 || input_length > 19) return -1;
    for (std::size_t i = 0; i < input_length; ++i) if (!std::isfinite(input[i])) return -1;
    int n, k;
    if (!exact_integer(input[0], 1, 4, n) || !exact_integer(input[1], 1, 4, k) ||
        k > n || input_length != static_cast<std::size_t>(2 + n * n)) return -1;
    for (int row = 0; row < n; ++row) {
        for (int col = 0; col < n; ++col) {
            int entry;
            if (!exact_integer(input[2 + row * n + col], -4, 4, entry) ||
                input[2 + row * n + col] != input[2 + col * n + row]) return -1;
        }
    }
    const auto required = static_cast<std::size_t>(2 * k);
    if (output == nullptr || output_capacity < required) return -2;

    double previous[4]{}, current[4]{}, product[4]{}, residual[4]{}, next[4]{};
    double diagonal[4]{}, off_diagonal[3]{};
    current[0] = 1.0;
    double previous_beta = 0.0;
    for (int step = 0; step < k; ++step) {
        for (int row = 0; row < n; ++row) {
            product[row] = 0.0;
            for (int col = 0; col < n; ++col)
                product[row] += input[2 + row * n + col] * current[col];
        }
        double alpha = 0.0;
        for (int index = 0; index < n; ++index) alpha += current[index] * product[index];
        if (!std::isfinite(alpha)) return -3;
        diagonal[step] = alpha;
        if (step + 1 == k) break;
        double norm_squared = 0.0;
        for (int index = 0; index < n; ++index) {
            residual[index] = product[index] - alpha * current[index] - previous_beta * previous[index];
            norm_squared += residual[index] * residual[index];
        }
        if (!std::isfinite(norm_squared) || norm_squared < 0.0) return -3;
        const double beta = std::sqrt(norm_squared);
        if (!std::isfinite(beta) || beta <= 9.094947017729282e-13) return -3;
        off_diagonal[step] = beta;
        for (int index = 0; index < n; ++index) next[index] = residual[index] / beta;
        for (int index = 0; index < n; ++index) previous[index] = current[index];
        for (int index = 0; index < n; ++index) current[index] = next[index];
        previous_beta = beta;
    }
    output[0] = static_cast<double>(k);
    for (int index = 0; index < k; ++index) output[1 + index] = diagonal[index];
    for (int index = 0; index < k - 1; ++index) output[1 + k + index] = off_diagonal[index];
    return static_cast<std::int64_t>(required);
}
