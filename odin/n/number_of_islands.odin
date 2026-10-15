package number_of_islands

import "core:c"

flood :: proc "contextless" (cells: [^]i64, visited: [^]bool, rows, cols, row, col: i64) {
    if row < 0 || col < 0 || row >= rows || col >= cols do return
    index := row * cols + col
    if cells[index] != 1 || visited[index] do return
    visited[index] = true
    flood(cells, visited, rows, cols, row + 1, col)
    flood(cells, visited, rows, cols, row - 1, col)
    flood(cells, visited, rows, cols, row, col + 1)
    flood(cells, visited, rows, cols, row, col - 1)
}

@(export)
number_of_islands :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 3 || values[0] < 1 || values[0] > 16 || values[1] < 1 || values[1] > 16 do return -1
    rows, cols := values[0], values[1]
    if length != c.size_t(2 + rows * cols) do return -1
    for i := c.size_t(2); i < length; i += 1 {
        if values[i] != 0 && values[i] != 1 do return -1
    }
    visited: [256]bool
    count := i64(0)
    cells := values + 2
    for row := i64(0); row < rows; row += 1 {
        for col := i64(0); col < cols; col += 1 {
            index := row * cols + col
            if cells[index] == 1 && !visited[index] {
                count += 1
                flood(cells, &visited[0], rows, cols, row, col)
            }
        }
    }
    return count
}
