const MAX_N: usize = 8;
fn countFrom(n: usize, column: usize, rows: *[MAX_N]bool, down: *[2 * MAX_N]bool, up: *[2 * MAX_N]bool) i64 {
    if (column == n) return 1;
    var count: i64 = 0;
    for (0..n) |row| {
        const d = row + n - 1 - column;
        const u = row + column;
        if (!rows[row] and !down[d] and !up[u]) {
            rows[row] = true; down[d] = true; up[u] = true;
            count += countFrom(n, column + 1, rows, down, up);
            rows[row] = false; down[d] = false; up[u] = false;
        }
    }
    return count;
}
export fn n_queens_solution_count(values: [*c]const i64, length: usize) i64 {
    if (values == null or length != 1 or values[0] < 0 or values[0] > @as(i64, @intCast(MAX_N))) return -1;
    var rows = [_]bool{false} ** MAX_N;
    var down = [_]bool{false} ** (2 * MAX_N);
    var up = [_]bool{false} ** (2 * MAX_N);
    return countFrom(@intCast(values[0]), 0, &rows, &down, &up);
}
