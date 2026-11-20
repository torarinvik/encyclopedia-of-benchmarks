#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 6;
constexpr std::size_t max_input = 15;
constexpr double grid_denominator = 18014398509481984.0;
constexpr double min_node_separation = 0.0625;
constexpr double min_magnitude = 0.03125;
constexpr double max_magnitude = 64.0;
constexpr double boundary_guard = 0.00000000023283064365386963;

bool finite_in_range(double value)
{
    return std::isfinite(value) && value >= -8.0 && value <= 8.0
        && std::trunc(value * grid_denominator) == value * grid_denominator;
}
}

extern "C" std::int64_t thiele_rational_interpolation(const double *input,
        std::size_t input_length, double *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length < 4 || input_length > max_input) return -1;
    const double n_value = input[0];
    if (!finite_in_range(n_value) || std::trunc(n_value) != n_value || n_value < 1.0 || n_value > max_n) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (input_length != 2 + 2 * n) return -1;

    double x[max_n]{}, y[max_n]{}, difference[max_n * max_n]{};
    for (std::size_t i = 0; i < n; ++i) {
        x[i] = input[1 + 2 * i];
        y[i] = input[2 + 2 * i];
        if (!finite_in_range(x[i]) || !finite_in_range(y[i])) return -1;
        for (std::size_t j = 0; j < i; ++j)
            if (x[i] == x[j] || std::abs(x[i] - x[j]) < min_node_separation) return -1;
        difference[i] = y[i];
    }
    const double query = input[input_length - 1];
    if (!finite_in_range(query)) return -1;

    for (std::size_t order = 1; order < n; ++order) {
        for (std::size_t endpoint = order; endpoint < n; ++endpoint) {
            const double denominator = difference[(order - 1) * max_n + order - 1]
                                     - difference[(order - 1) * max_n + endpoint];
            if (!std::isfinite(denominator) || std::abs(denominator) <= min_magnitude + boundary_guard || std::abs(denominator) >= max_magnitude - boundary_guard) return -1;
            const double value = (x[order - 1] - x[endpoint]) / denominator;
            if (!std::isfinite(value) || std::abs(value) >= max_magnitude - boundary_guard) return -1;
            difference[order * max_n + endpoint] = value;
        }
        if (std::abs(difference[order * max_n + order]) <= min_magnitude + boundary_guard || std::abs(difference[order * max_n + order]) >= max_magnitude - boundary_guard) return -1;
    }

    double result = 0.0;
    bool at_node = false;
    for (std::size_t i = 0; i < n; ++i) {
        if (query == x[i]) { result = y[i]; at_node = true; break; }
    }
    if (!at_node && n == 1) result = y[0];
    if (!at_node && n > 1) {
        double tail = difference[(n - 1) * max_n + n - 1];
        for (std::size_t order = n - 2; order > 0; --order) {
            if (!std::isfinite(tail) || std::abs(tail) <= min_magnitude + boundary_guard || std::abs(tail) >= max_magnitude - boundary_guard) return -1;
            tail = difference[order * max_n + order] + (query - x[order]) / tail;
            if (!std::isfinite(tail) || std::abs(tail) >= max_magnitude - boundary_guard) return -1;
        }
        if (!std::isfinite(tail) || std::abs(tail) <= min_magnitude + boundary_guard || std::abs(tail) >= max_magnitude - boundary_guard) return -1;
        result = y[0] + (query - x[0]) / tail;
    }
    if (!std::isfinite(result) || std::abs(result) >= max_magnitude - boundary_guard) return -1;
    if (output == nullptr || output_capacity < 1) return -2;
    output[0] = result;
    return 1;
}
