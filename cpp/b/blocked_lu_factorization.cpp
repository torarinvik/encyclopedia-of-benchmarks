#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 8;
constexpr std::size_t max_input_length = 66;
constexpr std::size_t max_output_elements = 128;

double rounded_mul(double a, double b) noexcept { volatile double x = a * b; return x; }
double rounded_add(double a, double b) noexcept { volatile double x = a + b; return x; }
double rounded_sub(double a, double b) noexcept { volatile double x = a - b; return x; }
double rounded_div(double a, double b) noexcept { volatile double x = a / b; return x; }

bool exact_integer(double x, std::int64_t lo, std::int64_t hi, std::int64_t& out) noexcept {
    if (!std::isfinite(x) || x < static_cast<double>(lo) || x > static_cast<double>(hi)) return false;
    const auto v = static_cast<std::int64_t>(x);
    if (static_cast<double>(v) != x) return false;
    out = v;
    return true;
}
}

extern "C" std::int64_t blocked_lu_factorization(const double* input, std::size_t input_length,
                                                double* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 1 || input_length > max_input_length) return -1;
    std::int64_t n_value;
    if (!exact_integer(input[0], 2, static_cast<std::int64_t>(max_n), n_value)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if ((n & 1U) != 0 || input_length != 1 + n * n) return -1;

    double schur[max_n * max_n]{};
    for (std::size_t row = 0; row < n; ++row) {
        std::int64_t off_sum = 0;
        for (std::size_t col = 0; col < n; ++col) {
            const auto p = row * n + col;
            std::int64_t value;
            if (!exact_integer(input[p + 1], row == col ? 1 : -2, row == col ? 16 : 2, value)) return -1;
            schur[p] = static_cast<double>(value);
            if (row != col) off_sum += value < 0 ? -value : value;
        }
        if (schur[row * n + row] <= static_cast<double>(off_sum)) return -1;
    }

    double lower[max_n * max_n]{};
    double upper[max_n * max_n]{};
    for (std::size_t k = 0; k < n; k += 2) {
        const double u00 = schur[k * n + k];
        const double u01 = schur[k * n + k + 1];
        if (!std::isfinite(u00) || u00 == 0.0) return -1;
        const double l10 = rounded_div(schur[(k + 1) * n + k], u00);
        const double u11 = rounded_sub(schur[(k + 1) * n + k + 1], rounded_mul(l10, u01));
        if (!std::isfinite(l10) || !std::isfinite(u11) || u11 == 0.0) return -1;
        lower[k * n + k] = 1.0;
        lower[(k + 1) * n + k] = l10;
        lower[(k + 1) * n + k + 1] = 1.0;
        upper[k * n + k] = u00;
        upper[k * n + k + 1] = u01;
        upper[(k + 1) * n + k + 1] = u11;
        for (std::size_t j = k + 2; j < n; j += 2) {
            for (std::size_t col = j; col < j + 2; ++col) {
                const double s0 = schur[k * n + col];
                const double s1 = schur[(k + 1) * n + col];
                upper[k * n + col] = s0;
                upper[(k + 1) * n + col] = rounded_sub(s1, rounded_mul(l10, s0));
            }
        }
        for (std::size_t i = k + 2; i < n; i += 2) {
            for (std::size_t row = i; row < i + 2; ++row) {
                const double s0 = schur[row * n + k];
                const double s1 = schur[row * n + k + 1];
                const double l0 = rounded_div(s0, u00);
                const double l1 = rounded_div(rounded_sub(s1, rounded_mul(l0, u01)), u11);
                lower[row * n + k] = l0;
                lower[row * n + k + 1] = l1;
            }
        }
        for (std::size_t i = k + 2; i < n; i += 2) {
            for (std::size_t j = k + 2; j < n; j += 2) {
                for (std::size_t row = i; row < i + 2; ++row) {
                    for (std::size_t col = j; col < j + 2; ++col) {
                        double update = rounded_mul(lower[row * n + k], upper[k * n + col]);
                        update = rounded_add(update, rounded_mul(lower[row * n + k + 1], upper[(k + 1) * n + col]));
                        schur[row * n + col] = rounded_sub(schur[row * n + col], update);
                    }
                }
            }
        }
    }
    double staged[max_output_elements]{};
    const auto matrix_elements = n * n;
    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t col = 0; col < n; ++col) {
            if (row == col) lower[row * n + col] = 1.0;
            if (row <= col) upper[row * n + col] = schur[row * n + col];
        }
    }
    for (std::size_t i = 0; i < matrix_elements; ++i) {
        if (!std::isfinite(lower[i]) || !std::isfinite(upper[i])) return -1;
        staged[i] = lower[i];
        staged[matrix_elements + i] = upper[i];
    }
    const auto output_length = 2 * matrix_elements;
    if (output == nullptr || output_capacity < output_length) return -2;
    for (std::size_t i = 0; i < output_length; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(output_length);
}
