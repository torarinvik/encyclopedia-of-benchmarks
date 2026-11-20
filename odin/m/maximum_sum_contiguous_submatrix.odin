package maximum_sum_contiguous_submatrix

import "core:c"

MAX_PARSEABLE_INPUT_LENGTH :: 67
OUTPUT_BYTES :: 8

@(export)
maximum_sum_contiguous_submatrix :: proc "contextless" (input: [^]i64,
        length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
    rows_value := input[0]
    columns_value := input[1]
    if rows_value < 1 || rows_value > 8 || columns_value < 1 || columns_value > 8 do return -1
    rows := int(rows_value)
    columns := int(columns_value)
    cells := rows * columns
    if length != c.size_t(2 + cells) do return -1
    for index := 0; index < cells; index += 1 {
        if input[index + 2] < -1000 || input[index + 2] > 1000 do return -1
    }

    best: i64 = -64001
    column_sums: [8]i64
    for top := 0; top < rows; top += 1 {
        for column := 0; column < columns; column += 1 { column_sums[column] = 0 }
        for bottom := top; bottom < rows; bottom += 1 {
            row_offset := 2 + bottom * columns
            for column := 0; column < columns; column += 1 {
                column_sums[column] += input[row_offset + column]
            }
            current := column_sums[0]
            if current > best do best = current
            for column := 1; column < columns; column += 1 {
                if current < 0 do current = column_sums[column]
                else do current += column_sums[column]
                if current > best do best = current
            }
        }
    }
    if output == nil || output_capacity < c.size_t(OUTPUT_BYTES) do return -2
    bits := u64(best)
    for byte := 0; byte < 8; byte += 1 {
        output[byte] = u8((bits >> (byte * 8)) & 255)
    }
    return i64(OUTPUT_BYTES)
}
