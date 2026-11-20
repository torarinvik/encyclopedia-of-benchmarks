#include <stddef.h>
#include <stdint.h>

enum { MAX_CELLS = 64, MAX_INPUT_WORDS = 68 };

int64_t recursive_backtracker_maze_generation(const int64_t *input, size_t length,
                                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_WORDS) return -1;
    const int64_t rows_word = input[0], cols_word = input[1];
    const int64_t start_word = input[2], draw_count_word = input[3];
    if (rows_word < 1 || rows_word > MAX_CELLS || cols_word < 1 || cols_word > MAX_CELLS) return -1;
    const size_t rows = (size_t)rows_word, cols = (size_t)cols_word;
    const size_t cells = rows * cols;
    if (cells > MAX_CELLS || start_word < 0 || (uint64_t)start_word >= cells ||
        draw_count_word != (int64_t)cells - 1 || length != 4 + cells - 1) return -1;
    for (size_t i = 0; i < cells - 1; ++i)
        if (input[4 + i] < 0 || input[4 + i] > 3) return -1;

    uint8_t visited[MAX_CELLS] = {0};
    uint8_t walls[MAX_CELLS];
    size_t stack[MAX_CELLS];
    for (size_t i = 0; i < cells; ++i) walls[i] = 15;
    size_t depth = 1, cursor = 0;
    stack[0] = (size_t)start_word;
    visited[stack[0]] = 1;
    while (depth != 0) {
        const size_t cell = stack[depth - 1];
        const size_t row = cell / cols, col = cell % cols;
        size_t candidate_cells[4], candidate_dirs[4], count = 0;
        if (row > 0 && !visited[cell - cols]) { candidate_cells[count] = cell - cols; candidate_dirs[count++] = 0; }
        if (col + 1 < cols && !visited[cell + 1]) { candidate_cells[count] = cell + 1; candidate_dirs[count++] = 1; }
        if (row + 1 < rows && !visited[cell + cols]) { candidate_cells[count] = cell + cols; candidate_dirs[count++] = 2; }
        if (col > 0 && !visited[cell - 1]) { candidate_cells[count] = cell - 1; candidate_dirs[count++] = 3; }
        if (count == 0) { --depth; continue; }
        if (cursor >= cells - 1) return -1;
        const size_t choice = (size_t)input[4 + cursor++];
        if (choice >= count) return -1;
        const size_t next = candidate_cells[choice], direction = candidate_dirs[choice];
        visited[next] = 1;
        walls[cell] &= (uint8_t)~(1u << direction);
        walls[next] &= (uint8_t)~(1u << ((direction + 2) & 3u));
        stack[depth++] = next;
    }
    if (cursor != cells - 1) return -1;
    for (size_t i = 0; i < cells; ++i) if (!visited[i]) return -1;
    if (output == NULL || capacity < cells) return -2;
    for (size_t i = 0; i < cells; ++i) output[i] = walls[i];
    return (int64_t)cells;
}
