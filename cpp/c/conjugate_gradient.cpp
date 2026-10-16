#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t max_dimension = 8;
constexpr std::int64_t max_entry_micro = 1'000'000'000;
constexpr double scale = 1'000'000.0;
constexpr double tolerance = 1.0e-10;
constexpr std::size_t max_iterations = 1000;

void write_f64_le(std::uint8_t *output, std::size_t offset, double value) noexcept {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t conjugate_gradient(
    const std::int64_t *values, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept {
    if (values == nullptr || length < 1 || values[0] < 1 || values[0] > static_cast<std::int64_t>(max_dimension)) return -1;
    const auto n = static_cast<std::size_t>(values[0]);
    if (length != 1 + n * n + n) return -1;
    const std::size_t vector_offset = 1 + n * n;
    double matrix[max_dimension * max_dimension]{};
    double rhs[max_dimension]{};
    double solution[max_dimension]{};
    double residual[max_dimension]{};
    double direction[max_dimension]{};
    double product[max_dimension]{};
    for (std::size_t index = 0; index < n * n + n; ++index)
        if (values[index + 1] < -max_entry_micro || values[index + 1] > max_entry_micro) return -1;

    for (std::size_t row = 0; row < n; ++row) {
        const auto diagonal = values[1 + row * n + row];
        if (diagonal <= 0) return -1;
        std::int64_t off_diagonal_sum = 0;
        for (std::size_t column = 0; column < n; ++column) {
            const auto entry = values[1 + row * n + column];
            if (entry != values[1 + column * n + row]) return -1;
            if (column != row) off_diagonal_sum += entry < 0 ? -entry : entry;
            matrix[row * n + column] = static_cast<double>(entry) / scale;
        }
        if (diagonal <= off_diagonal_sum) return -1;
        rhs[row] = static_cast<double>(values[vector_offset + row]) / scale;
        residual[row] = rhs[row];
        direction[row] = rhs[row];
    }
    const std::size_t output_bytes = n * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;

    double residual_squared = 0.0;
    for (std::size_t index = 0; index < n; ++index) residual_squared += residual[index] * residual[index];
    for (std::size_t iteration = 0; iteration < max_iterations && residual_squared > tolerance * tolerance; ++iteration) {
        for (std::size_t row = 0; row < n; ++row) {
            product[row] = 0.0;
            for (std::size_t column = 0; column < n; ++column)
                product[row] += matrix[row * n + column] * direction[column];
        }
        double denominator = 0.0;
        for (std::size_t index = 0; index < n; ++index) denominator += direction[index] * product[index];
        if (!(denominator > 0.0) || !std::isfinite(denominator)) return -1;
        const double alpha = residual_squared / denominator;
        for (std::size_t index = 0; index < n; ++index) {
            solution[index] += alpha * direction[index];
            residual[index] -= alpha * product[index];
        }
        double next_residual_squared = 0.0;
        for (std::size_t index = 0; index < n; ++index) next_residual_squared += residual[index] * residual[index];
        if (next_residual_squared <= tolerance * tolerance) {
            residual_squared = next_residual_squared;
            break;
        }
        const double beta = next_residual_squared / residual_squared;
        for (std::size_t index = 0; index < n; ++index)
            direction[index] = residual[index] + beta * direction[index];
        residual_squared = next_residual_squared;
    }
    for (std::size_t index = 0; index < n; ++index) {
        if (!std::isfinite(solution[index])) return -1;
        write_f64_le(output, index * 8, solution[index]);
    }
    return static_cast<std::int64_t>(output_bytes);
}
