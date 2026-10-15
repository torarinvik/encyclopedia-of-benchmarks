package pascal_triangle_row

import "core:c"

// Compute one row of Pascal's triangle using in-place dynamic programming.
@(export)
pascal_triangle_row :: proc "c" (row_index: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if row_index < 0 || row_index > 33 do return -1
    count := c.size_t(row_index + 1)
    required := count * 4
    if output == nil || output_capacity < required do return -2

    coefficients: [34]u32 = {}
    for column := 0; column < int(count); column += 1 {
        coefficients[column] = 1
    }
    for row := 2; row <= int(row_index); row += 1 {
        for column := row - 1; column > 0; column -= 1 {
            coefficients[column] += coefficients[column - 1]
        }
    }

    position := c.size_t(0)
    for column := 0; column < int(count); column += 1 {
        for byte := 0; byte < 4; byte += 1 {
            coefficients_value := coefficients[column]
            output[position] = u8((coefficients_value >> u32(byte*8)) & 255)
            position += 1
        }
    }
    return i64(position)
}
