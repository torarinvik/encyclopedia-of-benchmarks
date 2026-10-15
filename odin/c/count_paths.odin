package count_paths

import "core:c"

// Count four-neighbor vertex-simple grid paths by recursive DFS.
count_from :: proc "contextless" (values: [^]i64, rows, cols: i64, row, col: i64, visited: u32) -> i64 {
    if row < 0 || col < 0 || row >= rows || col >= cols do return 0
    index := row * cols + col
    mask := u32(1) << u32(index)
    if values[2 + index] == 1 || (visited & mask) != 0 do return 0
    if row == rows - 1 && col == cols - 1 do return 1
    seen := visited | mask
    count := i64(0)
    count += count_from(values, rows, cols, row + 1, col, seen)
    count += count_from(values, rows, cols, row - 1, col, seen)
    count += count_from(values, rows, cols, row, col + 1, seen)
    count += count_from(values, rows, cols, row, col - 1, seen)
    return count
}

@(export)
count_paths :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 3 || values[0] < 1 || values[0] > 5 || values[1] < 1 || values[1] > 5 do return -1
    rows, cols := values[0], values[1]
    if rows * cols > 25 || length != c.size_t(2 + rows * cols) do return -1
    for i := c.size_t(2); i < length; i += 1 {
        if values[i] != 0 && values[i] != 1 do return -1
    }
    return count_from(values, rows, cols, 0, 0, 0)
}
