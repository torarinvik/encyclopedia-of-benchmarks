module rat_in_amaze;

const usz MAX_DIMENSION = 4;
const usz MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION;
const usz MAX_PATH_LENGTH = MAX_CELLS - 1;
const usz MAX_PARSEABLE_INPUT_LENGTH = 19;
const usz MAX_OUTPUT_WORDS = 2097;
const usz MAX_OUTPUT_BYTES = MAX_OUTPUT_WORDS * 8;

struct Maze {
    int variant;
    usz size;
    long[MAX_CELLS] cells;
}

struct Paths {
    long[MAX_OUTPUT_WORDS] words;
    usz word_count;
    usz count;
}

fn void direction(int variant, int movement, int* delta_row, int* delta_col, int* code) {
    if (variant == 0) {
        if (movement == 0) { delta_row[0] = 1; delta_col[0] = 0; code[0] = 0; }
        else if (movement == 1) { delta_row[0] = 0; delta_col[0] = -1; code[0] = 1; }
        else if (movement == 2) { delta_row[0] = 0; delta_col[0] = 1; code[0] = 2; }
        else { delta_row[0] = -1; delta_col[0] = 0; code[0] = 3; }
    } else {
        if (movement == 0) { delta_row[0] = 0; delta_col[0] = 1; code[0] = 2; }
        else if (movement == 1) { delta_row[0] = 1; delta_col[0] = 0; code[0] = 0; }
        else if (movement == 2) { delta_row[0] = -1; delta_col[0] = 0; code[0] = 3; }
        else { delta_row[0] = 0; delta_col[0] = -1; code[0] = 1; }
    }
}

fn bool collect_paths(Maze* maze, int row, int col, uint8* visited, uint8* current,
                      usz path_length, Paths* paths) {
    if (row == (int)maze->size - 1 && col == (int)maze->size - 1) {
        paths->words[paths->word_count] = (long)path_length;
        paths->word_count++;
        for (usz index = 0; index < path_length; index++) {
            paths->words[paths->word_count] = (long)current[index];
            paths->word_count++;
        }
        paths->count++;
        paths->words[0] = (long)paths->count;
        return maze->variant == 1;
    }

    usz index = (usz)row * maze->size + (usz)col;
    visited[index] = 1;
    for (int movement = 0; movement < 4; movement++) {
        int delta_row;
        int delta_col;
        int code;
        direction(maze->variant, movement, &delta_row, &delta_col, &code);
        int next_row = row + delta_row;
        int next_col = col + delta_col;
        if (next_row < 0 || next_col < 0 || next_row >= (int)maze->size || next_col >= (int)maze->size) continue;
        usz next_index = (usz)next_row * maze->size + (usz)next_col;
        if (maze->cells[next_index] != 1 || visited[next_index] != 0) continue;
        current[path_length] = (uint8)code;
        if (collect_paths(maze, next_row, next_col, visited, current, path_length + 1, paths)) {
            visited[index] = 0;
            return true;
        }
    }
    visited[index] = 0;
    return false;
}

fn bool parse_maze(long* values, usz length, Maze* maze) {
    if (values == null || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return false;
    if (length < 2 || (values[0] != 0 && values[0] != 1)) return false;
    if (values[1] < 1 || values[1] > (long)MAX_DIMENSION) return false;
    usz size = (usz)values[1];
    if (length != 2 + size * size) return false;
    maze->variant = (int)values[0];
    maze->size = size;
    for (usz index = 0; index < size * size; index++) {
        long cell = values[2 + index];
        if (cell != 0 && cell != 1) return false;
        maze->cells[index] = cell;
    }
    return true;
}

fn void write_i64_le(uint8* output, usz offset, long value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255);
        bits >>= 8;
    }
}

fn long rat_in_amaze(long* values, usz length, uint8* output, usz output_capacity)
    @export("rat_in_amaze") {
    Maze maze;
    if (!parse_maze(values, length, &maze)) return -1L;

    Paths paths;
    paths.word_count = 1;
    paths.count = 0;
    paths.words[0] = 0;
    if (maze.cells[0] == 1 && maze.cells[maze.size * maze.size - 1] == 1) {
        uint8[MAX_CELLS] visited = zeroed;
        uint8[MAX_PATH_LENGTH] current = zeroed;
        collect_paths(&maze, 0, 0, &visited[0], &current[0], 0, &paths);
    }
    if (paths.count == 0) return -3L;

    usz output_bytes = paths.word_count * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1L;
    if (output == null || output_capacity < output_bytes) return -2L;
    for (usz index = 0; index < paths.word_count; index++)
        write_i64_le(output, index * 8, paths.words[index]);
    return (long)output_bytes;
}
