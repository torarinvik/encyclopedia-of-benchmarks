#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 8;
constexpr std::size_t max_input_length = 66;
constexpr std::size_t max_output_elements = 72;

bool exact_integer(double x, std::int64_t lo, std::int64_t hi, std::int64_t& out) noexcept {
    if (!std::isfinite(x) || x < static_cast<double>(lo) || x > static_cast<double>(hi)) return false;
    const auto value = static_cast<std::int64_t>(x);
    if (static_cast<double>(value) != x) return false;
    out = value;
    return true;
}
}

extern "C" std::int64_t hpl_blocked_partial_pivot_lu(
    const double* input, std::size_t input_length, double* output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 1 || input_length > max_input_length) return -1;
    std::int64_t raw_n;
    if (!exact_integer(input[0], 2, static_cast<std::int64_t>(max_n), raw_n)) return -1;
    const auto n = static_cast<std::size_t>(raw_n);
    if (input_length != 1 + n * n) return -1;

    double a[max_n * max_n]{};
    for (std::size_t i = 0; i < n * n; ++i) {
        std::int64_t value;
        if (!exact_integer(input[i + 1], -16, 16, value)) return -1;
        a[i] = static_cast<double>(value);
    }
    std::size_t pivots[max_n]{};
    for (std::size_t panel = 0; panel < n;) {
        const std::size_t panel_end = panel + 2 < n ? panel + 2 : n;
        for (std::size_t col = panel; col < panel_end; ++col) {
            std::size_t pivot_row = col;
            double pivot_magnitude = std::abs(a[col * n + col]);
            for (std::size_t row = col + 1; row < n; ++row) {
                const double magnitude = std::abs(a[row * n + col]);
                if (magnitude > pivot_magnitude) {
                    pivot_magnitude = magnitude;
                    pivot_row = row;
                }
            }
            if (!std::isfinite(pivot_magnitude) || pivot_magnitude == 0.0) return -1;
            pivots[col] = pivot_row;
            if (pivot_row != col) {
                for (std::size_t j = 0; j < n; ++j) {
                    const double temporary = a[col * n + j];
                    a[col * n + j] = a[pivot_row * n + j];
                    a[pivot_row * n + j] = temporary;
                }
            }
            const double diagonal = a[col * n + col];
            if (!std::isfinite(diagonal) || diagonal == 0.0) return -1;
            for (std::size_t row = col + 1; row < n; ++row) {
                a[row * n + col] /= diagonal;
                if (!std::isfinite(a[row * n + col])) return -1;
                const double multiplier = a[row * n + col];
                for (std::size_t j = col + 1; j < panel_end; ++j) {
                    a[row * n + j] -= multiplier * a[col * n + j];
                    if (!std::isfinite(a[row * n + j])) return -1;
                }
            }
        }
        for (std::size_t row = panel; row < panel_end; ++row) {
            for (std::size_t col = panel_end; col < n; ++col) {
                double value = a[row * n + col];
                for (std::size_t inner = panel; inner < row; ++inner)
                    value -= a[row * n + inner] * a[inner * n + col];
                if (!std::isfinite(value)) return -1;
                a[row * n + col] = value;
            }
        }
        for (std::size_t row = panel_end; row < n; ++row) {
            for (std::size_t col = panel_end; col < n; ++col) {
                double update = 0.0;
                for (std::size_t inner = panel; inner < panel_end; ++inner)
                    update += a[row * n + inner] * a[inner * n + col];
                a[row * n + col] -= update;
                if (!std::isfinite(a[row * n + col])) return -1;
            }
        }
        panel = panel_end;
    }

    double staged[max_output_elements]{};
    for (std::size_t i = 0; i < n; ++i) staged[i] = static_cast<double>(pivots[i]);
    for (std::size_t i = 0; i < n * n; ++i) {
        if (!std::isfinite(a[i])) return -1;
        staged[n + i] = a[i];
    }
    const std::size_t output_length = n + n * n;
    if (output == nullptr || output_capacity < output_length) return -2;
    for (std::size_t i = 0; i < output_length; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(output_length);
}
