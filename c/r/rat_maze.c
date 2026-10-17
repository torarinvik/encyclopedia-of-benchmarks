#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_INPUT_WORDS (1 + MAX_N * MAX_N)
#define MAX_OUTPUT_WORDS (1 + MAX_N * MAX_N)
#define MAX_OUTPUT_BYTES (4 * MAX_OUTPUT_WORDS)

static bool search_path(const int32_t *maze, int32_t *path, int n, int row, int col) {
    const int index = row * n + col;
    path[index] = 1;
    if (row == n - 1 && col == n - 1) return true;
    if (col + 1 < n && maze[index + 1] == 1 && search_path(maze, path, n, row, col + 1)) return true;
    if (row + 1 < n && maze[index + n] == 1 && search_path(maze, path, n, row + 1, col)) return true;
    path[index] = 0;
    return false;
}

static void put_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t rat_maze(const int32_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_WORDS) return -1;
    const int32_t n = input[0];
    if (n < 1 || n > MAX_N || length != 1 + (size_t)n * (size_t)n || input[1] != 1) return -1;
    for (size_t i = 0; i < (size_t)n * (size_t)n; ++i) if (input[1 + i] < 0 || input[1 + i] > 1) return -1;
    int32_t path[MAX_N * MAX_N] = {0};
    const bool found = search_path(input + 1, path, n, 0, 0);
    const size_t word_count = found ? 1 + (size_t)n * (size_t)n : 1;
    const size_t bytes = word_count * 4;
    if (output == NULL || capacity < bytes) return -2;
    uint8_t buffer[MAX_OUTPUT_BYTES];
    put_i32_le(buffer, 0, found ? 1 : 0);
    if (found) for (size_t i = 0; i < (size_t)n * (size_t)n; ++i) put_i32_le(buffer, (i + 1) * 4, path[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return (int64_t)bytes;
}
