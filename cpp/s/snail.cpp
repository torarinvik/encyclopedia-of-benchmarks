#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_rows = 16;
constexpr int max_columns = 16;
constexpr std::size_t max_cells = 256;
constexpr std::size_t max_input_length = 259;

void write_i32_le(std::uint8_t *output, std::size_t index, std::int32_t value) {
    const std::uint32_t bits = static_cast<std::uint32_t>(value);
    const std::size_t offset = index * 4;
    output[offset] = static_cast<std::uint8_t>(bits);
    output[offset + 1] = static_cast<std::uint8_t>(bits >> 8);
    output[offset + 2] = static_cast<std::uint8_t>(bits >> 16);
    output[offset + 3] = static_cast<std::uint8_t>(bits >> 24);
}
}

extern "C" std::int64_t snail(const std::int32_t *values, std::size_t length,
                               std::uint8_t *output, std::size_t output_capacity) {
    if (values == nullptr || length < 2 || length > max_input_length) return -1;
    const std::int32_t rows_value = values[0], columns_value = values[1];
    if (rows_value < 0 || rows_value > max_rows
        || columns_value < 0 || columns_value > max_columns) return -1;
    if (rows_value == 0 && columns_value != 0) return -1;
    if (columns_value == 1 && rows_value != 1) return -1;

    const int rows = static_cast<int>(rows_value);
    const int columns = static_cast<int>(columns_value);
    const std::size_t cell_count = static_cast<std::size_t>(rows * columns);
    if (length != 2 + cell_count) return -1;

    const std::size_t required_bytes = 4 * cell_count;
    if (output == nullptr || output_capacity < required_bytes) return -2;
    if (cell_count == 0) return 0;

    std::int32_t matrix[max_cells]{};
    for (std::size_t index = 0; index < cell_count; ++index)
        matrix[index] = values[2 + index];

    int top = 0, bottom = rows - 1, left = 0, right = columns - 1;
    std::size_t written = 0;
    while (top <= bottom && left <= right) {
        for (int column = left; column <= right; ++column)
            write_i32_le(output, written++, matrix[static_cast<std::size_t>(top * columns + column)]);
        ++top;

        for (int row = top; row <= bottom; ++row)
            write_i32_le(output, written++, matrix[static_cast<std::size_t>(row * columns + right)]);
        --right;

        if (top <= bottom && left <= right) {
            for (int column = right; column >= left; --column)
                write_i32_le(output, written++, matrix[static_cast<std::size_t>(bottom * columns + column)]);
            --bottom;
        }

        if (top <= bottom && left <= right) {
            for (int row = bottom; row >= top; --row)
                write_i32_le(output, written++, matrix[static_cast<std::size_t>(row * columns + left)]);
            ++left;
        }
    }
    return static_cast<std::int64_t>(required_bytes);
}
