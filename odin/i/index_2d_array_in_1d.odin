package index_2d_array_in_1d

import "core:c"

@(export)
index_2d_array_in_1d :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 4 do return -1
    rows, cols, index := input[0], input[1], input[2]
    if rows < 1 || rows > 32 || cols < 1 || cols > 32 do return -1
    cells := usize(rows*cols)
    if length != c.size_t(cells+3) || index < 0 || index >= rows*cols do return -1
    for i: usize = 0; i < cells; i += 1 { if input[3+i] < 0 || input[3+i] > 1000000 do return -1 }
    row, col := usize(index / cols), usize(index % cols)
    return input[3+row*usize(cols)+col]
}
