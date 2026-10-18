module rat_in_maze;

const usz MAX_DIMENSION = 8;
const usz MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION;
const usz MAX_PARSEABLE_INPUT_LENGTH = 71;
const usz MAX_OUTPUT_BYTES = MAX_CELLS * 8;
const int PYTHON_VARIANT = 0;
const int RUST_VARIANT = 1;

struct Maze {
    int variant;
    usz rows;
    usz cols;
    usz start_row;
    usz start_col;
    usz destination_row;
    usz destination_col;
    long[MAX_CELLS] cells;
}

fn void direction(int variant, int move, int* delta_row, int* delta_col) {
    if (variant == PYTHON_VARIANT) {
        if (move == 0) { delta_row[0] = 1; delta_col[0] = 0; }
        else if (move == 1) { delta_row[0] = 0; delta_col[0] = 1; }
        else if (move == 2) { delta_row[0] = -1; delta_col[0] = 0; }
        else { delta_row[0] = 0; delta_col[0] = -1; }
    } else {
        if (move == 0) { delta_row[0] = 0; delta_col[0] = 1; }
        else if (move == 1) { delta_row[0] = 1; delta_col[0] = 0; }
        else if (move == 2) { delta_row[0] = 0; delta_col[0] = -1; }
        else { delta_row[0] = -1; delta_col[0] = 0; }
    }
}

fn bool search_path(Maze* maze, int row, int col, uint8* path) {
    if (maze->variant == RUST_VARIANT && row == (int)maze->destination_row &&
        col == (int)maze->destination_col) {
        path[(usz)row * maze->cols + (usz)col] = 1;
        return true;
    }
    if (row < 0 || col < 0 || row >= (int)maze->rows || col >= (int)maze->cols) return false;

    usz index = (usz)row * maze->cols + (usz)col;
    long open_value = maze->variant == PYTHON_VARIANT ? 0 : 1;
    if (maze->cells[index] != open_value || path[index] != 0) return false;
    path[index] = 1;
    if (maze->variant == PYTHON_VARIANT && row == (int)maze->destination_row &&
        col == (int)maze->destination_col) return true;

    for (int move = 0; move < 4; move++) {
        int delta_row;
        int delta_col;
        direction(maze->variant, move, &delta_row, &delta_col);
        if (search_path(maze, row + delta_row, col + delta_col, path)) return true;
    }
    path[index] = 0;
    return false;
}

fn bool parse_maze(long* values, usz length, Maze* maze) {
    if (values == null || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return false;
    if (values[0] == PYTHON_VARIANT) {
        if (length < 7 || values[1] < 1 || values[1] > (long)MAX_DIMENSION) return false;
        usz size = (usz)values[1];
        if (length != 6 + size * size) return false;
        if (values[2] < 0 || values[2] >= (long)size || values[3] < 0 || values[3] >= (long)size ||
            values[4] < 0 || values[4] >= (long)size || values[5] < 0 || values[5] >= (long)size) return false;
        maze->variant = PYTHON_VARIANT;
        maze->rows = size;
        maze->cols = size;
        maze->start_row = (usz)values[2];
        maze->start_col = (usz)values[3];
        maze->destination_row = (usz)values[4];
        maze->destination_col = (usz)values[5];
        for (usz index = 0; index < size * size; index++) {
            long cell = values[6 + index];
            if (cell != 0 && cell != 1) return false;
            maze->cells[index] = cell;
        }
    } else if (values[0] == RUST_VARIANT) {
        if (length < 6 || values[1] < 1 || values[1] > (long)MAX_DIMENSION ||
            values[2] < 1 || values[2] > (long)MAX_DIMENSION) return false;
        usz rows = (usz)values[1];
        usz cols = (usz)values[2];
        if (length != 5 + rows * cols || values[3] < 0 || values[3] >= (long)rows ||
            values[4] < 0 || values[4] >= (long)cols) return false;
        maze->variant = RUST_VARIANT;
        maze->rows = rows;
        maze->cols = cols;
        maze->start_row = (usz)values[3];
        maze->start_col = (usz)values[4];
        maze->destination_row = rows - 1;
        maze->destination_col = cols - 1;
        for (usz index = 0; index < rows * cols; index++) {
            long cell = values[5 + index];
            if (cell != 0 && cell != 1) return false;
            maze->cells[index] = cell;
        }
    } else return false;
    return true;
}

fn void write_i64_le(uint8* output, usz offset, long value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255);
        bits >>= 8;
    }
}

fn long rat_in_maze(long* values, usz length, uint8* output, usz output_capacity)
    @export("rat_in_maze") {
    Maze maze;
    if (!parse_maze(values, length, &maze)) return -1L;
    uint8[MAX_CELLS] path = zeroed;
    if (!search_path(&maze, (int)maze.start_row, (int)maze.start_col, &path[0])) return -3L;

    usz cells = maze.rows * maze.cols;
    usz output_bytes = cells * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1L;
    if (output == null || output_capacity < output_bytes) return -2L;
    for (usz index = 0; index < cells; index++) {
        long value = maze.variant == PYTHON_VARIANT ? (path[index] != 0 ? 0L : 1L) : (path[index] != 0 ? 1L : 0L);
        write_i64_le(output, index * 8, value);
    }
    return (long)output_bytes;
}
