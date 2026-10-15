module count_paths;

fn long count_from(long* grid, uint rows, uint cols, int row, int col, uint visited) {
    if (row < 0 || col < 0 || row >= (int)rows || col >= (int)cols) return 0;
    uint index = (uint)row * cols + (uint)col;
    uint mask = 1 << index;
    if (grid[index] == 1 || (visited & mask) != 0) return 0;
    if ((uint)row == rows - 1 && (uint)col == cols - 1) return 1;
    uint seen = visited | mask;
    long count = 0;
    count += count_from(grid, rows, cols, row + 1, col, seen);
    count += count_from(grid, rows, cols, row - 1, col, seen);
    count += count_from(grid, rows, cols, row, col + 1, seen);
    count += count_from(grid, rows, cols, row, col - 1, seen);
    return count;
}

fn long count_paths(long* values, usz length) @export("count_paths") {
    if (values == null || length < 3 || values[0] < 1 || values[0] > 5 || values[1] < 1 || values[1] > 5) return -1;
    uint rows = (uint)values[0];
    uint cols = (uint)values[1];
    if (rows * cols > 25 || length != (usz)2 + (usz)(rows * cols)) return -1;
    for (usz i = 2; i < length; i++) if (values[i] != 0 && values[i] != 1) return -1;
    return count_from(values + 2, rows, cols, 0, 0, 0);
}
