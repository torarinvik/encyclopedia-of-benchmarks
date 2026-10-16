#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_dimension = 6;
constexpr std::int64_t max_entry_micro = 1'000'000'000;

void write_f64_le(std::uint8_t *output, std::size_t offset, double value) noexcept {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t cholesky_decomposition(
    const std::int64_t *values, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 1 || values[0] < 1 || values[0] > max_dimension) return -1;
    const auto n = static_cast<std::size_t>(values[0]);
    if (length != 1 + n * n) return -1;

    double matrix[max_dimension * max_dimension]{};
    double lower[max_dimension * max_dimension]{};
    for (std::size_t index = 0; index < n * n; ++index) {
        const auto scaled = values[index + 1];
        if (scaled < -max_entry_micro || scaled > max_entry_micro) return -1;
        matrix[index] = static_cast<double>(scaled) / 1'000'000.0;
    }
    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t column = 0; column < n; ++column) {
            const double left = matrix[row * n + column];
            const double right = matrix[column * n + row];
            if (std::abs(left - right) > 1.0e-8 + 1.0e-5 * std::abs(right)) return -1;
        }
    }

    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t column = 0; column <= row; ++column) {
            double sum = 0.0;
            for (std::size_t index = 0; index < column; ++index)
                sum += lower[row * n + index] * lower[column * n + index];
            const double residual = matrix[row * n + column] - sum;
            if (row == column) {
                if (residual <= 0.0) return -1;
                lower[row * n + column] = std::sqrt(residual);
            } else {
                lower[row * n + column] = residual / lower[column * n + column];
            }
        }
    }

    const std::size_t output_bytes = n * n * 8;
    if (output_bytes > output_capacity || output == nullptr) return -2;
    for (std::size_t index = 0; index < n * n; ++index)
        write_f64_le(output, index * 8, lower[index]);
    return static_cast<std::int64_t>(output_bytes);
}
