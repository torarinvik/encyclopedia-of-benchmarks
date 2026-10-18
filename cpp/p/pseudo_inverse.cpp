#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_rows = 4;
constexpr std::size_t max_input_length = 7;
constexpr double singular_value_cutoff = 1e-4;

bool integer_in_range(double value, int minimum, int maximum) noexcept {
    return std::isfinite(value) && value >= static_cast<double>(minimum) &&
        value <= static_cast<double>(maximum) && value == std::trunc(value);
}
}

extern "C" std::int64_t pseudo_inverse(const double* input, std::size_t input_length,
    double* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 3 || input_length > max_input_length) return -1;
    for (std::size_t index = 0; index < input_length; ++index) {
        if (!std::isfinite(input[index])) return -1;
    }
    if (!integer_in_range(input[0], 1, static_cast<int>(max_rows)) || !integer_in_range(input[1], 1, 1)) return -1;
    const auto row_count = static_cast<std::size_t>(input[0]);
    const auto column_count = static_cast<std::size_t>(input[1]);
    if (input_length != 2 + row_count * column_count || input_length > 2 + max_rows) return -1;

    double column[max_rows];
    double squared_norm = 0.0;
    for (std::size_t row = 0; row < row_count; ++row) {
        const double value = input[2 + row];
        if (value < -4.0 || value > 4.0 || value != std::trunc(value)) return -1;
        column[row] = value;
        squared_norm += value * value;
    }
    const double singular_value = std::sqrt(squared_norm);
    double staged[2 + max_rows];
    staged[0] = 1.0;
    staged[1] = static_cast<double>(row_count);
    for (std::size_t row = 0; row < row_count; ++row) {
        staged[2 + row] = std::abs(singular_value) < singular_value_cutoff
            ? 0.0 : column[row] / squared_norm;
    }

    const std::size_t result_length = 2 + row_count;
    if (output == nullptr || output_capacity < result_length) return -2;
    for (std::size_t index = 0; index < result_length; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(result_length);
}
