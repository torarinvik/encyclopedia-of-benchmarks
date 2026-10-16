module n_queens_solution_count;
const int MAX_N = 8;
fn long count_from(int n, int column, bool* rows, bool* down, bool* up) {
    if (column == n) return 1;
    long count = 0;
    for (int row = 0; row < n; row++) {
        int d = row - column + n - 1, u = row + column;
        if (!rows[row] && !down[d] && !up[u]) {
            rows[row] = true; down[d] = true; up[u] = true;
            count += count_from(n, column + 1, rows, down, up);
            rows[row] = false; down[d] = false; up[u] = false;
        }
    }
    return count;
}
fn long n_queens_solution_count(long* values, usz length) @export("n_queens_solution_count") {
    if (values == null || length != 1 || values[0] < 0 || values[0] > MAX_N) return -1;
    bool[MAX_N] rows;
    bool[2 * MAX_N] down, up;
    for (int i = 0; i < MAX_N; i++) rows[i] = false;
    for (int i = 0; i < 2 * MAX_N; i++) { down[i] = false; up[i] = false; }
    return count_from((int)values[0], 0, &rows[0], &down[0], &up[0]);
}
