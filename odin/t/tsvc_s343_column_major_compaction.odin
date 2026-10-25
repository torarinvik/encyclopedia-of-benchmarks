package tsvc_s343_column_major_compaction

import "core:c"

MAX_ROWS :: 8
MAX_COLS :: 8
MAX_CELLS :: MAX_ROWS * MAX_COLS
MAX_INPUT_LENGTH :: 2 + 2 * MAX_CELLS
BYTES_PER_VALUE :: 8

store_i64_le :: proc "contextless" (output: [^]u8, position: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < BYTES_PER_VALUE; byte += 1 {
        output[position + byte] = u8((bits >> u64(byte * 8)) & 255)
    }
}

@(export)
tsvc_s343_column_major_compaction :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 4 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    rows_raw := input[0]
    cols_raw := input[1]
    if rows_raw < 1 || rows_raw > MAX_ROWS || cols_raw < 1 || cols_raw > MAX_COLS do return -1
    rows := int(rows_raw)
    cols := int(cols_raw)
    cells := rows * cols
    if int(length) != 2 + 2 * cells do return -1
    if output == nil || output_capacity < c.size_t(cells * BYTES_PER_VALUE) do return -2

    data_start := 2
    mask_start := data_start + cells
    written := 0
    for col := 0; col < cols; col += 1 {
        for row := 0; row < rows; row += 1 {
            index := row * cols + col
            if input[mask_start + index] > 0 {
                store_i64_le(output, written * BYTES_PER_VALUE, input[data_start + index])
                written += 1
            }
        }
    }
    return i64(written)
}
