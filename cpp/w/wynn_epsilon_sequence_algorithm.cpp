#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 10;
constexpr std::size_t max_input_length = 13;
constexpr std::size_t max_order = 6;

bool wynn_is_valid_sample(double value) noexcept {
    const double scaled = value * 256.0;
    return std::isfinite(value) && value >= -2.0 && value <= 2.0
        && std::floor(scaled) == scaled;
}
}

extern "C" std::int64_t wynn_epsilon_sequence_algorithm(
    const double *input, std::size_t input_length,
    double *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 3 || input_length > max_input_length) return -1;
    for (std::size_t i = 0; i < input_length; ++i) if (!std::isfinite(input[i])) return -1;
    const double n_value = input[0], k_value = input[1];
    if (std::floor(n_value) != n_value || std::floor(k_value) != k_value
        || n_value < 5.0 || n_value > static_cast<double>(max_n)
        || k_value < 2.0 || k_value > 3.0) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto k = static_cast<std::size_t>(k_value);
    if (n < 2 * k + 1 || input_length != n + 2) return -1;
    for (std::size_t i = 0; i < n; ++i) if (!wynn_is_valid_sample(input[i + 2])) return -1;

    double rows[max_order + 1][max_n]{};
    bool valid[max_order + 1][max_n]{};
    for (std::size_t i = 0; i < n; ++i) {
        rows[0][i] = input[i + 2];
        valid[0][i] = true;
    }
    for (std::size_t order = 0; order < 2 * k; ++order) {
        const std::size_t width = n - order - 1;
        for (std::size_t i = 0; i < width; ++i) {
            const bool auxiliary_valid = order == 0 || valid[order - 1][i + 1];
            if (!valid[order][i] || !valid[order][i + 1] || !auxiliary_valid) continue;
            const double denominator = rows[order][i + 1] - rows[order][i];
            if (denominator == 0.0 || !std::isfinite(denominator)) continue;
            const double reciprocal = 1.0 / denominator;
            const double auxiliary = order == 0 ? 0.0 : rows[order - 1][i + 1];
            const double value = auxiliary + reciprocal;
            if (!std::isfinite(reciprocal) || !std::isfinite(value)) continue;
            rows[order + 1][i] = value;
            valid[order + 1][i] = true;
        }
    }

    std::size_t needed = 0;
    for (std::size_t order = 2; order <= 2 * k; order += 2) needed += 2 * (n - order);
    if (output == nullptr || output_capacity < needed) return -2;
    std::size_t cursor = 0;
    for (std::size_t order = 2; order <= 2 * k; order += 2) {
        for (std::size_t i = 0; i < n - order; ++i) {
            output[cursor++] = valid[order][i] ? 0.0 : 1.0;
            output[cursor++] = valid[order][i] ? rows[order][i] : 0.0;
        }
    }
    return static_cast<std::int64_t>(needed);
}
