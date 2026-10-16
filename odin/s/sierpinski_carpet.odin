package sierpinski_carpet

import "core:c"

write_i64_le :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
    bits := u64(value)
    for byte: usize = 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

is_filled :: proc "contextless" (row_start, col_start: usize) -> bool {
    row, col := row_start, col_start
    for row != 0 || col != 0 {
        if row % 3 == 1 && col % 3 == 1 do return false
        row /= 3
        col /= 3
    }
    return true
}

@(export, link_name="sierpinski_carpet")
sierpinski_carpet :: proc "c" (input: [^]i64, length: c.size_t,
                                output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length != 3 do return -1
    depth, filled, hole := input[0], input[1], input[2]
    if depth < 0 || depth > 4 || filled < 32 || filled > 126 ||
        hole < 32 || hole > 126 || filled == hole do return -1
    side: usize = 1
    for level: i64 = 0; level < depth; level += 1 do side *= 3
    needed := 8 + side * side + side - 1
    if output == nil || capacity < c.size_t(needed) do return -2

    write_i64_le(output, 0, i64(side))
    out: usize = 8
    for row: usize = 0; row < side; row += 1 {
        for col: usize = 0; col < side; col += 1 {
            output[out] = u8(if is_filled(row, col) { filled } else { hole })
            out += 1
        }
        if row + 1 < side {
            output[out] = 10
            out += 1
        }
    }
    return i64(needed)
}
