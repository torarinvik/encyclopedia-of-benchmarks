package n_queens_solution_count

import "core:c"

MAX_N :: 8

count_from :: proc(n, column: int, rows: ^[MAX_N]bool, down, up: ^[2 * MAX_N]bool) -> i64 {
    if column == n do return 1
    count: i64 = 0
    for row := 0; row < n; row += 1 {
        d := row - column + n - 1
        u := row + column
        if !rows[row] && !down[d] && !up[u] {
            rows[row] = true; down[d] = true; up[u] = true
            count += count_from(n, column + 1, rows, down, up)
            rows[row] = false; down[d] = false; up[u] = false
        }
    }
    return count
}

@(export)
n_queens_solution_count :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != 1 || values[0] < 0 || values[0] > MAX_N do return -1
    rows: [MAX_N]bool
    down, up: [2 * MAX_N]bool
    return count_from(int(values[0]), 0, &rows, &down, &up)
}
