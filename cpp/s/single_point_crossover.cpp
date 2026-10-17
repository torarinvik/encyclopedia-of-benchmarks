#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_parent_length = 31;
constexpr std::size_t max_input_length = 2 + 2 * max_parent_length;
}

extern "C" std::int64_t single_point_crossover(const double *input, std::size_t input_length,
                                                 double *output, std::size_t output_capacity) {
    if (input == nullptr || input_length < 6 || input_length > max_input_length) return -1;
    const double n_value = input[0];
    const double cut_value = input[1];
    if (!std::isfinite(n_value) || n_value < 2.0 || n_value > max_parent_length || std::floor(n_value) != n_value ||
        !std::isfinite(cut_value) || cut_value < 1.0 || cut_value > n_value - 1.0 || std::floor(cut_value) != cut_value) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto cut = static_cast<std::size_t>(cut_value);
    if (input_length != 2 + 2 * n) return -1;
    double first[max_parent_length], second[max_parent_length];
    for (std::size_t index = 0; index < n; ++index) {
        first[index] = input[2 + index];
        second[index] = input[2 + n + index];
        if (!std::isfinite(first[index]) || !std::isfinite(second[index])) return -1;
    }
    const std::size_t required = 2 * n;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t index = 0; index < n; ++index) {
        output[index] = index < cut ? first[index] : second[index];
        output[n + index] = index < cut ? second[index] : first[index];
    }
    return static_cast<std::int64_t>(required);
}
