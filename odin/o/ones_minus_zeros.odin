package ones_minus_zeros

import "core:c"

MAX_CELLS :: 100_000
MAX_DIMENSION :: 100_000

read_count :: proc "contextless" (output: [^]u8, cell: int) -> i64 {
    position := 4 * cell
    return i64(output[position]) | (i64(output[position + 1]) << 8) |
        (i64(output[position + 2]) << 16) | (i64(output[position + 3]) << 24)
}

write_i32_le :: proc "contextless" (output: [^]u8, cell: int, value: i64) {
    encoded := value
    if encoded < 0 do encoded += 4_294_967_296
    position := 4 * cell
    output[position] = u8(encoded & 255)
    output[position + 1] = u8((encoded >> 8) & 255)
    output[position + 2] = u8((encoded >> 16) & 255)
    output[position + 3] = u8((encoded >> 24) & 255)
}

@(export)
ones_minus_zeros :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if values == nil || length < 2 || values[0] < 1 || values[0] > MAX_DIMENSION ||
        values[1] < 1 || values[1] > MAX_DIMENSION {
        return -1
    }
    rows := int(values[0])
    columns := int(values[1])
    if rows > MAX_CELLS / columns do return -1
    cells := rows * columns
    if length != c.size_t(2 + cells) do return -1
    for cell := 0; cell < cells; cell += 1 {
        value := values[2 + cell]
        if value != 0 && value != 1 do return -1
    }
    required := c.size_t(4 * cells)
    if output == nil || output_capacity < required do return -2

    for byte := 0; byte < 4 * cells; byte += 1 do output[byte] = 0
    row_zero_ones: i64 = 0
    column_zero_ones: i64 = 0
    for row := 0; row < rows; row += 1 {
        for column := 0; column < columns; column += 1 {
            if values[2 + row * columns + column] == 0 do continue
            if row == 0 {
                row_zero_ones += 1
            } else {
                slot := row * columns
                write_i32_le(output, slot, read_count(output, slot) + 1)
            }
            if column == 0 {
                column_zero_ones += 1
            } else {
                write_i32_le(output, column, read_count(output, column) + 1)
            }
        }
    }
    for row := rows; row > 1; row -= 1 {
        current_row := row - 1
        row_slot := current_row * columns
        row_ones := read_count(output, row_slot)
        for column := 0; column < columns; column += 1 {
            column_ones := column_zero_ones
            if column != 0 do column_ones = read_count(output, column)
            difference := 2 * row_ones + 2 * column_ones - i64(rows) - i64(columns)
            write_i32_le(output, row_slot + column, difference)
        }
    }
    for column := 0; column < columns; column += 1 {
        column_ones := column_zero_ones
        if column != 0 do column_ones = read_count(output, column)
        difference := 2 * row_zero_ones + 2 * column_ones - i64(rows) - i64(columns)
        write_i32_le(output, column, difference)
    }
    return i64(cells)
}
