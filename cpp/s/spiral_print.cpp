#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr int max_rows = 16;
constexpr int max_columns = 16;
constexpr std::size_t max_cells = 256;
constexpr std::size_t max_input_length = 259;

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int32_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(static_cast<std::int64_t>(value));
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t spiral_print(const std::int64_t *input, std::size_t length,
                                       std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const std::int64_t rows_value = input[0], columns_value = input[1];
    if (rows_value < 1 || rows_value > max_rows || columns_value < 2 || columns_value > max_columns) return -1;
    const int rows = static_cast<int>(rows_value), columns = static_cast<int>(columns_value);
    const std::size_t cell_count = static_cast<std::size_t>(rows * columns);
    if (length != 2 + cell_count) return -1;

    std::int32_t matrix[max_cells];
    for (std::size_t index = 0; index < cell_count; ++index) {
        const std::int64_t value = input[2 + index];
        if (value < std::numeric_limits<std::int32_t>::min() ||
            value > std::numeric_limits<std::int32_t>::max()) return -1;
        matrix[index] = static_cast<std::int32_t>(value);
    }

    const std::size_t required_bytes = 8 * cell_count;
    if (output == nullptr || capacity < required_bytes) return -2;

    int top = 0, bottom = rows - 1, left = 0, right = columns - 1;
    std::size_t output_index = 0;
    while (top <= bottom && left <= right) {
        for (int column = left; column <= right; ++column)
            write_i64_le(output, 8 * output_index++, matrix[top * columns + column]);
        ++top;

        for (int row = top; row <= bottom; ++row)
            write_i64_le(output, 8 * output_index++, matrix[row * columns + right]);
        --right;

        if (top <= bottom && left <= right) {
            for (int column = right; column >= left; --column)
                write_i64_le(output, 8 * output_index++, matrix[bottom * columns + column]);
            --bottom;
        }

        if (top <= bottom && left <= right) {
            for (int row = bottom; row >= top; --row)
                write_i64_le(output, 8 * output_index++, matrix[row * columns + left]);
            ++left;
        }
    }
    return static_cast<std::int64_t>(required_bytes);
}
