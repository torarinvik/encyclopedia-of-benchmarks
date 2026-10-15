#include <cstddef>
#include <cstdint>
#include <cstring>

static std::int64_t read_count(const std::uint8_t *output, std::size_t cell)
{
    const std::size_t position = 4 * cell;
    return static_cast<std::int64_t>(
        static_cast<std::uint32_t>(output[position]) |
        (static_cast<std::uint32_t>(output[position + 1]) << 8) |
        (static_cast<std::uint32_t>(output[position + 2]) << 16) |
        (static_cast<std::uint32_t>(output[position + 3]) << 24));
}

static void write_i32_le(std::uint8_t *output, std::size_t cell, std::int64_t value)
{
    const auto encoded = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
    const std::size_t position = 4 * cell;
    output[position] = static_cast<std::uint8_t>(encoded);
    output[position + 1] = static_cast<std::uint8_t>(encoded >> 8);
    output[position + 2] = static_cast<std::uint8_t>(encoded >> 16);
    output[position + 3] = static_cast<std::uint8_t>(encoded >> 24);
}

extern "C" std::int64_t ones_minus_zeros(const std::int64_t *values, std::size_t length,
                                          std::uint8_t *output, std::size_t output_capacity)
{
    if (values == nullptr || length < 2 || values[0] < 1 || values[0] > 100'000 ||
        values[1] < 1 || values[1] > 100'000) return -1;
    const auto rows = static_cast<std::size_t>(values[0]);
    const auto columns = static_cast<std::size_t>(values[1]);
    if (rows > 100'000 / columns) return -1;
    const std::size_t cells = rows * columns;
    if (length != 2 + cells) return -1;
    for (std::size_t cell = 0; cell < cells; ++cell)
        if (values[2 + cell] != 0 && values[2 + cell] != 1) return -1;
    const std::size_t required = 4 * cells;
    if (output == nullptr || output_capacity < required) return -2;

    std::memset(output, 0, required);
    std::int64_t row_zero_ones = 0;
    std::int64_t column_zero_ones = 0;
    for (std::size_t row = 0; row < rows; ++row) {
        for (std::size_t column = 0; column < columns; ++column) {
            if (values[2 + row * columns + column] == 0) continue;
            if (row == 0) ++row_zero_ones;
            else {
                const std::size_t slot = row * columns;
                write_i32_le(output, slot, read_count(output, slot) + 1);
            }
            if (column == 0) ++column_zero_ones;
            else write_i32_le(output, column, read_count(output, column) + 1);
        }
    }

    for (std::size_t row = rows; row > 1; --row) {
        const std::size_t current_row = row - 1;
        const std::size_t row_slot = current_row * columns;
        const std::int64_t row_ones = read_count(output, row_slot);
        for (std::size_t column = 0; column < columns; ++column) {
            const std::int64_t column_ones = column == 0 ? column_zero_ones : read_count(output, column);
            const std::int64_t difference = 2 * row_ones + 2 * column_ones -
                static_cast<std::int64_t>(rows) - static_cast<std::int64_t>(columns);
            write_i32_le(output, row_slot + column, difference);
        }
    }
    for (std::size_t column = 0; column < columns; ++column) {
        const std::int64_t column_ones = column == 0 ? column_zero_ones : read_count(output, column);
        const std::int64_t difference = 2 * row_zero_ones + 2 * column_ones -
            static_cast<std::int64_t>(rows) - static_cast<std::int64_t>(columns);
        write_i32_le(output, column, difference);
    }
    return static_cast<std::int64_t>(cells);
}
