#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_dimension = 8;
constexpr std::size_t max_input_length = 67;
constexpr std::size_t max_cells = 64;
constexpr std::int64_t min_cell = -1'000'000;
constexpr std::int64_t max_cell = 1'000'000;

void write_i64_le(std::uint8_t *output, std::size_t position, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t set_matrix_zeroes(const std::int64_t *input, std::size_t length,
                                           std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const auto rows_value = input[0];
    const auto columns_value = input[1];
    if (rows_value < 1 || rows_value > max_dimension || columns_value < 1 || columns_value > max_dimension) return -1;
    const auto rows = static_cast<std::size_t>(rows_value);
    const auto columns = static_cast<std::size_t>(columns_value);
    const auto cells = rows * columns;
    if (length != 2 + cells) return -1;

    std::int64_t matrix[max_cells];
    for (std::size_t index = 0; index < cells; ++index) {
        const auto value = input[2 + index];
        if (value < min_cell || value > max_cell) return -1;
        matrix[index] = value;
    }

    const auto bytes = cells * 8;
    if (output == nullptr || capacity < bytes) return -2;

    bool first_column_zero = false;
    for (std::size_t row = 0; row < rows; ++row) {
        if (matrix[row * columns] == 0) first_column_zero = true;
        for (std::size_t column = 1; column < columns; ++column) {
            if (matrix[row * columns + column] == 0) {
                matrix[row * columns] = 0;
                matrix[column] = 0;
            }
        }
    }
    for (std::size_t row = 1; row < rows; ++row) {
        for (std::size_t column = 1; column < columns; ++column) {
            if (matrix[row * columns] == 0 || matrix[column] == 0)
                matrix[row * columns + column] = 0;
        }
    }
    if (matrix[0] == 0) {
        for (std::size_t column = 0; column < columns; ++column) matrix[column] = 0;
    }
    if (first_column_zero) {
        for (std::size_t row = 0; row < rows; ++row) matrix[row * columns] = 0;
    }

    for (std::size_t index = 0; index < cells; ++index) write_i64_le(output, index * 8, matrix[index]);
    return static_cast<std::int64_t>(bytes);
}
