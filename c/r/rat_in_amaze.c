#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum {
    MAX_DIMENSION = 4,
    MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION,
    MAX_PATHS = 184,
    MAX_PATH_LENGTH = MAX_CELLS - 1,
    MAX_PARSEABLE_INPUT_LENGTH = 19,
    MAX_OUTPUT_WORDS = 2097,
    MAX_OUTPUT_BYTES = MAX_OUTPUT_WORDS * 8
};

enum { JAVA_VARIANT = 0, JAVASCRIPT_VARIANT = 1 };

typedef struct {
    int variant;
    size_t size;
    int64_t cells[MAX_CELLS];
} Maze;

typedef struct {
    uint8_t directions[MAX_PATHS][MAX_PATH_LENGTH];
    size_t lengths[MAX_PATHS];
    size_t count;
} Paths;

static const int moves[2][4][3] = {
    {{1, 0, 0}, {0, -1, 1}, {0, 1, 2}, {-1, 0, 3}},
    {{0, 1, 2}, {1, 0, 0}, {-1, 0, 3}, {0, -1, 1}}
};

static bool parse_maze(const int64_t *values, size_t length, Maze *maze)
{
    if (values == NULL || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return false;
    if (values[0] != JAVA_VARIANT && values[0] != JAVASCRIPT_VARIANT) return false;
    if (length < 2 || values[1] < 1 || values[1] > MAX_DIMENSION) return false;
    const size_t size = (size_t)values[1];
    const size_t cell_count = size * size;
    if (length != 2 + cell_count) return false;

    maze->variant = (int)values[0];
    maze->size = size;
    for (size_t index = 0; index < cell_count; ++index) {
        const int64_t cell = values[2 + index];
        if (cell != 0 && cell != 1) return false;
        maze->cells[index] = cell;
    }
    return true;
}

static bool collect_paths(const Maze *maze, int row, int col,
                          uint8_t visited[MAX_CELLS],
                          uint8_t current[MAX_PATH_LENGTH], size_t path_length,
                          Paths *paths)
{
    if (row == (int)maze->size - 1 && col == (int)maze->size - 1) {
        const size_t slot = paths->count++;
        paths->lengths[slot] = path_length;
        for (size_t index = 0; index < path_length; ++index)
            paths->directions[slot][index] = current[index];
        return maze->variant == JAVASCRIPT_VARIANT;
    }

    const size_t index = (size_t)row * maze->size + (size_t)col;
    visited[index] = 1;
    for (size_t movement = 0; movement < 4; ++movement) {
        const int next_row = row + moves[maze->variant][movement][0];
        const int next_col = col + moves[maze->variant][movement][1];
        if (next_row < 0 || next_col < 0 || next_row >= (int)maze->size ||
            next_col >= (int)maze->size) continue;
        const size_t next_index = (size_t)next_row * maze->size + (size_t)next_col;
        if (maze->cells[next_index] != 1 || visited[next_index] != 0) continue;
        current[path_length] = (uint8_t)moves[maze->variant][movement][2];
        if (collect_paths(maze, next_row, next_col, visited, current,
                          path_length + 1, paths)) {
            visited[index] = 0;
            return true;
        }
    }
    visited[index] = 0;
    return false;
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(0xff));
        bits >>= 8;
    }
}

int64_t rat_in_amaze(const int64_t *values, size_t length,
                     uint8_t *output, size_t output_capacity)
{
    Maze maze = {0};
    if (!parse_maze(values, length, &maze)) return -1;

    Paths paths = {0};
    if (maze.cells[0] == 1 && maze.cells[maze.size * maze.size - 1] == 1) {
        uint8_t visited[MAX_CELLS] = {0};
        uint8_t current[MAX_PATH_LENGTH] = {0};
        collect_paths(&maze, 0, 0, visited, current, 0, &paths);
    }
    if (paths.count == 0) return -3;

    size_t output_words = 1;
    for (size_t path = 0; path < paths.count; ++path)
        output_words += 1 + paths.lengths[path];
    const size_t output_bytes = output_words * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || output_capacity < output_bytes) return -2;

    size_t offset = 0;
    write_i64_le(output, offset, (int64_t)paths.count);
    offset += 8;
    for (size_t path = 0; path < paths.count; ++path) {
        write_i64_le(output, offset, (int64_t)paths.lengths[path]);
        offset += 8;
        for (size_t move = 0; move < paths.lengths[path]; ++move) {
            write_i64_le(output, offset, (int64_t)paths.directions[path][move]);
            offset += 8;
        }
    }
    return (int64_t)output_bytes;
}
