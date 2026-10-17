#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 63;
constexpr std::size_t max_input_values = 3 + max_dimension * max_dimension;
constexpr std::int64_t max_abs_cell = 1'000'000'000'000LL;
constexpr double cell_scale = 1.0e12;
constexpr double tolerance = 1.0e-9;
}

extern "C" std::int64_t stochastic_matrix(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > max_input_values) return -1;
    const auto mode = input[0];
    const auto rows_value = input[1];
    const auto columns_value = input[2];
    if ((mode != 0 && mode != 1) || rows_value < 1 || rows_value > static_cast<std::int64_t>(max_dimension) ||
        columns_value < 1 || columns_value > static_cast<std::int64_t>(max_dimension)) return -1;

    const auto rows = static_cast<std::size_t>(rows_value);
    const auto columns = static_cast<std::size_t>(columns_value);
    const auto total = rows * columns;
    if (length != 3 + total) return -1;

    for (std::size_t index = 0; index < total; ++index) {
        const auto units = input[3 + index];
        if (units < -max_abs_cell || units > max_abs_cell) return -1;
    }

    if (mode == 0) {
        for (std::size_t row = 0; row < rows; ++row) {
            double sum = 0.0;
            for (std::size_t column = 0; column < columns; ++column) {
                const double value = static_cast<double>(input[3 + row * columns + column]) / cell_scale;
                if (value < 0.0) return 0;
                sum += value;
            }
            const double difference = sum - 1.0;
            if (difference > tolerance || difference < -tolerance) return 0;
        }
    } else {
        for (std::size_t column = 0; column < columns; ++column) {
            double sum = 0.0;
            for (std::size_t row = 0; row < rows; ++row) {
                const double value = static_cast<double>(input[3 + row * columns + column]) / cell_scale;
                if (value < 0.0) return 0;
                sum += value;
            }
            const double difference = sum - 1.0;
            if (difference > tolerance || difference < -tolerance) return 0;
        }
    }
    return 1;
}
