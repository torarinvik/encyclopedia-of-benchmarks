#include <stddef.h>
#include <stdint.h>

#define ASTAR_MAX_NODES 256

typedef struct {
    int32_t x;
    int32_t y;
    int32_t g;
    int32_t f;
    int32_t parent;
} SearchNode;

static void write_i64(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (unsigned shift = 0; shift < 64; shift += 8) {
        output[offset++] = (uint8_t)(bits >> shift);
    }
}

int64_t astar(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    static const int32_t dx[8] = {-1, -1, -1, 0, 0, 1, 1, 1};
    static const int32_t dy[8] = {-1, 0, 1, -1, 1, -1, 0, 1};
    if (input == NULL || length != 6) return -1;
    const int64_t rows64 = input[0], cols64 = input[1];
    const int64_t sx64 = input[2], sy64 = input[3], gx64 = input[4], gy64 = input[5];
    if (rows64 < 1 || rows64 > 16 || cols64 < 1 || cols64 > 16 ||
        sx64 < 0 || sx64 >= rows64 || sy64 < 0 || sy64 >= cols64 ||
        gx64 < 0 || gx64 >= rows64 || gy64 < 0 || gy64 >= cols64) return -1;
    const int32_t rows = (int32_t)rows64, cols = (int32_t)cols64;
    const int32_t sx = (int32_t)sx64, sy = (int32_t)sy64;
    const int32_t gx = (int32_t)gx64, gy = (int32_t)gy64;
    SearchNode nodes[ASTAR_MAX_NODES];
    int32_t open[ASTAR_MAX_NODES];
    size_t node_count = 1, open_count = 1;
    nodes[0] = (SearchNode){sx, sy, 0, 0, -1};
    open[0] = 0;
    int32_t current = 0;
    int found = 0;
    while (open_count > 0) {
        size_t best = 0;
        for (size_t i = 1; i < open_count; ++i) {
            if (nodes[open[i]].f < nodes[open[best]].f) best = i;
        }
        current = open[best];
        for (size_t i = best + 1; i < open_count; ++i) open[i - 1] = open[i];
        --open_count;
        if (nodes[current].x == gx && nodes[current].y == gy) {
            found = 1;
            break;
        }
        for (size_t neighbor = 0; neighbor < 8; ++neighbor) {
            const int32_t x = nodes[current].x + dx[neighbor];
            const int32_t y = nodes[current].y + dy[neighbor];
            if (x < 0 || x >= rows || y < 0 || y >= cols) continue;
            if (node_count >= ASTAR_MAX_NODES || open_count >= ASTAR_MAX_NODES) return -1;
            const int32_t g = nodes[current].g + 1;
            const int32_t ex = gx - x, ey = gy - y;
            const int32_t f = g + ex * ex + ey * ey;
            nodes[node_count] = (SearchNode){x, y, g, f, current};
            open[open_count++] = (int32_t)node_count++;
        }
    }
    if (!found) return -1;
    size_t path_count = 0;
    for (int32_t cursor = current; cursor >= 0; cursor = nodes[cursor].parent) ++path_count;
    const size_t output_bytes = path_count * 16;
    if (output == NULL || capacity < output_bytes) return -2;
    size_t offset = output_bytes;
    for (int32_t cursor = current; cursor >= 0; cursor = nodes[cursor].parent) {
        offset -= 16;
        write_i64(output, offset, nodes[cursor].x);
        write_i64(output, offset + 8, nodes[cursor].y);
    }
    return (int64_t)output_bytes;
}
