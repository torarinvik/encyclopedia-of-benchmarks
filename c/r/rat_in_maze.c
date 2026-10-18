#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum {
    MAX_DIMENSION = 8,
    MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION,
    MAX_PARSEABLE_INPUT_LENGTH = 71,
    MAX_OUTPUT_BYTES = MAX_CELLS * 8
};

enum { PYTHON_VARIANT = 0, RUST_VARIANT = 1 };

typedef struct {
    int variant;
    size_t rows;
    size_t cols;
    size_t start_row;
    size_t start_col;
    size_t destination_row;
    size_t destination_col;
    int64_t cells[MAX_CELLS];
} Maze;

static const int directions[2][4][2] = {
    {{1, 0}, {0, 1}, {-1, 0}, {0, -1}},
    {{0, 1}, {1, 0}, {0, -1}, {-1, 0}}
};

static bool search_path(const Maze *maze, int row, int col, uint8_t *path)
{
    if (maze->variant == RUST_VARIANT &&
        row == (int)maze->destination_row && col == (int)maze->destination_col) {
        path[(size_t)row * maze->cols + (size_t)col] = 1;
        return true;
    }
    if (row < 0 || col < 0 || row >= (int)maze->rows || col >= (int)maze->cols)
        return false;

    const size_t index = (size_t)row * maze->cols + (size_t)col;
    const int64_t open_value = maze->variant == PYTHON_VARIANT ? 0 : 1;
    if (maze->cells[index] != open_value || path[index] != 0) return false;
    path[index] = 1;

    if (maze->variant == PYTHON_VARIANT &&
        row == (int)maze->destination_row && col == (int)maze->destination_col)
        return true;

    for (size_t move = 0; move < 4; ++move) {
        if (search_path(maze, row + directions[maze->variant][move][0],
                        col + directions[maze->variant][move][1], path))
            return true;
    }
    path[index] = 0;
    return false;
}

static bool parse_maze(const int64_t *values, size_t length, Maze *maze)
{
    if (values == NULL || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return false;
    if (values[0] == PYTHON_VARIANT) {
        if (length < 7 || values[1] < 1 || values[1] > MAX_DIMENSION) return false;
        const size_t size = (size_t)values[1];
        if (length != 6 + size * size) return false;
        maze->variant = PYTHON_VARIANT;
        maze->rows = size;
        maze->cols = size;
        if (values[2] < 0 || values[2] >= (int64_t)size ||
            values[3] < 0 || values[3] >= (int64_t)size ||
            values[4] < 0 || values[4] >= (int64_t)size ||
            values[5] < 0 || values[5] >= (int64_t)size) return false;
        maze->start_row = (size_t)values[2];
        maze->start_col = (size_t)values[3];
        maze->destination_row = (size_t)values[4];
        maze->destination_col = (size_t)values[5];
        for (size_t index = 0; index < size * size; ++index) {
            const int64_t cell = values[6 + index];
            if (cell != 0 && cell != 1) return false;
            maze->cells[index] = cell;
        }
    } else if (values[0] == RUST_VARIANT) {
        if (length < 6 || values[1] < 1 || values[1] > MAX_DIMENSION ||
            values[2] < 1 || values[2] > MAX_DIMENSION) return false;
        const size_t rows = (size_t)values[1];
        const size_t cols = (size_t)values[2];
        if (length != 5 + rows * cols) return false;
        if (values[3] < 0 || values[3] >= (int64_t)rows ||
            values[4] < 0 || values[4] >= (int64_t)cols) return false;
        maze->variant = RUST_VARIANT;
        maze->rows = rows;
        maze->cols = cols;
        maze->start_row = (size_t)values[3];
        maze->start_col = (size_t)values[4];
        maze->destination_row = rows - 1;
        maze->destination_col = cols - 1;
        for (size_t index = 0; index < rows * cols; ++index) {
            const int64_t cell = values[5 + index];
            if (cell != 0 && cell != 1) return false;
            maze->cells[index] = cell;
        }
    } else {
        return false;
    }
    return true;
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(0xff));
        bits >>= 8;
    }
}

int64_t rat_in_maze(const int64_t *values, size_t length,
                    uint8_t *output, size_t output_capacity)
{
    Maze maze = {0};
    if (!parse_maze(values, length, &maze)) return -1;

    uint8_t path[MAX_CELLS] = {0};
    if (!search_path(&maze, (int)maze.start_row, (int)maze.start_col, path)) return -3;

    const size_t cells = maze.rows * maze.cols;
    const size_t output_bytes = cells * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || output_capacity < output_bytes) return -2;

    for (size_t index = 0; index < cells; ++index) {
        const int64_t value = maze.variant == PYTHON_VARIANT ?
            (path[index] != 0 ? 0 : 1) : (path[index] != 0 ? 1 : 0);
        write_i64_le(output, index * 8, value);
    }
    return (int64_t)output_bytes;
}
