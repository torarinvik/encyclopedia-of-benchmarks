#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#define MAX_DIMENSION 8
#define MAX_CELLS (MAX_DIMENSION * MAX_DIMENSION)
#define MAX_INPUT_LENGTH (5 + MAX_CELLS)
#define MAX_OUTPUT_VALUES (1 + MAX_CELLS)

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t bidirectional_breadth_first_search(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_DIMENSION || input[1] < 1 || input[1] > MAX_DIMENSION) return -1;
    const size_t rows = (size_t)input[0], cols = (size_t)input[1], cells = rows * cols;
    if (cells > MAX_CELLS || input[2] < 0 || input[2] >= (int64_t)cells || input[3] < 0 || input[3] >= (int64_t)cells) return -1;
    if (input[4] < 0 || input[4] > (int64_t)cells || length != 5 + (size_t)input[4]) return -1;
    const size_t start = (size_t)input[2], goal = (size_t)input[3], blocked_count = (size_t)input[4];
    uint8_t blocked[MAX_CELLS] = {0};
    for (size_t i = 0; i < blocked_count; ++i) {
        const int64_t value = input[5 + i];
        if (value < 0 || value >= (int64_t)cells) return -1;
        const size_t cell = (size_t)value;
        if (blocked[cell]) return -1;
        blocked[cell] = 1;
    }
    if (blocked[start] || blocked[goal]) return -1;

    int64_t distance[2][MAX_CELLS], parent[2][MAX_CELLS];
    size_t queue[2][MAX_CELLS];
    size_t head[2] = {0, 0}, tail[2] = {1, 1};
    for (size_t side = 0; side < 2; ++side)
        for (size_t cell = 0; cell < cells; ++cell) distance[side][cell] = parent[side][cell] = -1;
    distance[0][start] = distance[1][goal] = 0;
    queue[0][0] = start;
    queue[1][0] = goal;
    int64_t meeting = start == goal ? (int64_t)start : -1;
    while (meeting < 0 && head[0] < tail[0] && head[1] < tail[1]) {
      for (size_t side = 0; side < 2; ++side) {
        if (meeting >= 0) break;
        const size_t layer_end = tail[side];
        while (head[side] < layer_end) {
            const size_t node = queue[side][head[side]++];
            const size_t row = node / cols, col = node % cols;
            for (size_t direction = 0; direction < 4; ++direction) {
                size_t neighbor = 0;
                bool valid = false;
                if (direction == 0 && row > 0) { neighbor = node - cols; valid = true; }
                else if (direction == 1 && col > 0) { neighbor = node - 1; valid = true; }
                else if (direction == 2 && row + 1 < rows) { neighbor = node + cols; valid = true; }
                else if (direction == 3 && col + 1 < cols) { neighbor = node + 1; valid = true; }
                if (!valid || blocked[neighbor] || distance[side][neighbor] != -1) continue;
                distance[side][neighbor] = distance[side][node] + 1;
                parent[side][neighbor] = (int64_t)node;
                queue[side][tail++] = neighbor;
                if (distance[1 - side][neighbor] >= 0) { meeting = (int64_t)neighbor; break; }
            }
            if (meeting >= 0) break;
        }
      }
    }

    int64_t result[MAX_OUTPUT_VALUES];
    size_t result_count = 1;
    if (meeting < 0) result[0] = 0;
    else {
        size_t reverse_path[MAX_CELLS], prefix_count = 0, path_count = 0;
        int64_t current = meeting;
        while (current >= 0) {
            reverse_path[prefix_count++] = (size_t)current;
            if ((size_t)current == start) break;
            current = parent[0][(size_t)current];
        }
        for (size_t i = 0; i < prefix_count; ++i) result[1 + path_count++] = (int64_t)reverse_path[prefix_count - 1 - i];
        current = parent[1][(size_t)meeting];
        while (current >= 0) {
            result[1 + path_count++] = current;
            current = parent[1][(size_t)current];
        }
        result[0] = (int64_t)path_count;
        result_count += path_count;
    }
    const size_t output_bytes = result_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < result_count; ++i) put_i64_le(output, i * 8, result[i]);
    return (int64_t)output_bytes;
}
