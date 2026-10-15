module count_islands_in_matrix;

fn void flood(long* values, bool* visited, int rows, int cols, int row, int col) {
    if (row < 0 || col < 0 || row >= rows || col >= cols) return;
    int index = row * cols + col;
    if (values[2 + index] != 1 || visited[index]) return;
    visited[index] = true;
    for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
            if (dr != 0 || dc != 0) flood(values, visited, rows, cols, row + dr, col + dc);
        }
    }
}

fn long count_islands_in_matrix(long* values, usz length) @export("count_islands_in_matrix") {
    if (values == null || length < 3 || values[0] < 1 || values[0] > 16 || values[1] < 1 || values[1] > 16) return -1;
    int rows = (int)values[0];
    int cols = (int)values[1];
    if (length != (usz)(2 + rows * cols)) return -1;
    for (usz i = 2; i < length; i++) if (values[i] != 0 && values[i] != 1) return -1;
    bool[256] visited;
    long count = 0;
    for (int row = 0; row < rows; row++) {
        for (int col = 0; col < cols; col++) {
            int index = row * cols + col;
            if (values[2 + index] == 1 && !visited[index]) {
                count++;
                flood(values, &visited[0], rows, cols, row, col);
            }
        }
    }
    return count;
}
