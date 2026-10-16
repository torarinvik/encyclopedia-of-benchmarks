package floyd_triangle

import "core:c"

MAX_ROWS :: 90

@(export)
floyd_triangle :: proc "contextless" (rows: i64, output: [^]u8,
        output_capacity: c.size_t) -> i64 {
    if rows < 0 || rows > MAX_ROWS do return -1
    count := c.size_t(rows) * (c.size_t(rows) + 1) / 2
    output_length := count * 2
    if output_capacity < output_length || (output_length != 0 && output == nil) do return -2

    index := c.size_t(0)
    number: u32 = 1
    for row := c.size_t(1); row <= c.size_t(rows); row += 1 {
        for column := c.size_t(0); column < row; column += 1 {
            output[index * 2] = u8(number & 0xff)
            output[index * 2 + 1] = u8((number >> 8) & 0xff)
            number += 1
            index += 1
        }
    }
    return i64(output_length)
}
