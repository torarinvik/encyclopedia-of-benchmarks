package count_islands_in_matrix

import "core:c"

flood :: proc "contextless" (values: [^]i64, visited: [^]bool, rows, cols, row, col: i64) {
    if row < 0 || col < 0 || row >= rows || col >= cols do return
    index := row * cols + col
    if values[2 + index] != 1 || visited[index] do return
    visited[index] = true
    for dr := i64(-1); dr <= 1; dr += 1 {
        for dc := i64(-1); dc <= 1; dc += 1 {
            if dr != 0 || dc != 0 do flood(values, visited, rows, cols, row + dr, col + dc)
        }
    }
}

@(export)
count_islands_in_matrix :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 3 || values[0] < 1 || values[0] > 16 || values[1] < 1 || values[1] > 16 do return -1
    rows, cols := values[0], values[1]
    if length != c.size_t(2 + rows * cols) do return -1
    for i := c.size_t(2); i < length; i += 1 {
        if values[i] != 0 && values[i] != 1 do return -1
    }
    visited: [256]bool
    count := i64(0)
    for row := i64(0); row < rows; row += 1 {
        for col := i64(0); col < cols; col += 1 {
            index := row * cols + col
            if values[2 + index] == 1 && !visited[index] {
                count += 1
                flood(values, &visited[0], rows, cols, row, col)
            }
        }
    }
    return count
}
