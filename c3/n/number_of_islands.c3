module number_of_islands;

fn void flood(long* cells, bool* visited, int rows, int cols, int row, int col) {
    if (row < 0 || col < 0 || row >= rows || col >= cols) return;
    int index = row * cols + col;
    if (cells[index] != 1 || visited[index]) return;
    visited[index] = true;
    flood(cells, visited, rows, cols, row + 1, col);
    flood(cells, visited, rows, cols, row - 1, col);
    flood(cells, visited, rows, cols, row, col + 1);
    flood(cells, visited, rows, cols, row, col - 1);
}

fn long number_of_islands(long* values, usz length) @export("number_of_islands") {
    if (values == null || length < 3 || values[0] < 1 || values[0] > 16 || values[1] < 1 || values[1] > 16) return -1;
    int rows = (int)values[0], cols = (int)values[1];
    if (length != (usz)(2 + rows * cols)) return -1;
    long* cells = values + 2;
    for (int i = 0; i < rows * cols; i++) if (cells[i] != 0 && cells[i] != 1) return -1;
    bool[256] visited;
    long count = 0;
    for (int row = 0; row < rows; row++) for (int col = 0; col < cols; col++) {
        int index = row * cols + col;
        if (cells[index] == 1 && !visited[index]) {
            count++;
            flood(cells, &visited[0], rows, cols, row, col);
        }
    }
    return count;
}
