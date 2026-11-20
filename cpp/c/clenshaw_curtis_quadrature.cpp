/* Bounded Clenshaw-Curtis quadrature on supplied Lobatto-node samples. */
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_parseable_input_length = 19;
constexpr double pi = 3.14159265358979323846264338327950288;

bool exact_integer(double value, int low, int high, int& decoded) noexcept {
    if (!std::isfinite(value) || value < low || value > high || std::trunc(value) != value) return false;
    decoded = static_cast<int>(value);
    return true;
}

double compute(int n, const double* samples) noexcept {
    double result = 0.0;
    for (int k = 0; k <= n; ++k) {
        double inner = 0.0;
        for (int j = 1; j <= n / 2; ++j) {
            const double bj = j == n / 2 ? 1.0 : 2.0;
            const double denominator = static_cast<double>(4 * j * j - 1);
            const double angle = (((2.0 * static_cast<double>(j)) * static_cast<double>(k)) * pi) /
                                 static_cast<double>(n);
            const double term = (bj / denominator) * std::cos(angle);
            inner += term;
        }
        const double gk = (k == 0 || k == n) ? 1.0 : 2.0;
        const double weight = (gk / static_cast<double>(n)) * (1.0 - inner);
        result += weight * samples[k];
    }
    return result;
}
}

extern "C" std::int64_t clenshaw_curtis_quadrature(
    const double* input, std::size_t input_length, double* output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 4 || input_length > max_parseable_input_length) return -1;
    int n;
    if (!exact_integer(input[0], 2, 16, n) || (n % 2) != 0 || input_length != static_cast<std::size_t>(n) + 2) return -1;
    for (std::size_t i = 1; i < input_length; ++i)
        if (!std::isfinite(input[i]) || std::abs(input[i]) > 1000.0) return -1;
    if (output == nullptr || output_capacity < 1) return -2;
    const double result = compute(n, input + 1);
    if (!std::isfinite(result)) return -1;
    output[0] = result;
    return 1;
}
