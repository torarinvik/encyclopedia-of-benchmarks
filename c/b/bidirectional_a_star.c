#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS 20
#define MAX_COLS 20
#define MAX_CELLS (MAX_ROWS * MAX_COLS)
#define INF_COST 1000000

static int isqrt_floor(int value) { int result = 0; while ((result + 1) * (result + 1) <= value) ++result; return result; }
static int heuristic(int a, int b, int columns) { int dy = a / columns - b / columns, dx = a % columns - b % columns; return isqrt_floor(dy * dy + dx * dx); }
static void put_i64(uint8_t *out, size_t slot, int64_t value) { uint64_t bits = (uint64_t)value; for (size_t i = 0; i < 8; ++i) out[slot * 8 + i] = (uint8_t)(bits >> (i * 8)); }

int64_t bidirectional_a_star(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 6 || input[0] < 1 || input[0] > MAX_ROWS || input[1] < 1 || input[1] > MAX_COLS) return -1;
    int rows = (int)input[0], cols = (int)input[1], cells = rows * cols;
    int64_t sy = input[2], sx = input[3], gy = input[4], gx = input[5];
    if (sy < 0 || sy >= rows || sx < 0 || sx >= cols || gy < 0 || gy >= rows || gx < 0 || gx >= cols || length != (size_t)(6 + cells)) return -1;
    int start = (int)(sy * cols + sx), goal = (int)(gy * cols + gx);
    int64_t blocked[MAX_CELLS];
    for (int i = 0; i < cells; ++i) { blocked[i] = input[6 + i]; if (blocked[i] != 0 && blocked[i] != 1) return -1; }
    if (blocked[start] || blocked[goal]) return -1;
    int g[2][MAX_CELLS], parent[2][MAX_CELLS], order[2][MAX_CELLS];
    uint8_t opened[2][MAX_CELLS] = {{0}}, closed[2][MAX_CELLS] = {{0}};
    int next_order[2] = {0, 0};
    for (int side = 0; side < 2; ++side) for (int i = 0; i < cells; ++i) { g[side][i] = INF_COST; parent[side][i] = -1; order[side][i] = 0; }
    g[0][start] = g[1][goal] = 0; opened[0][start] = opened[1][goal] = 1; order[0][start] = next_order[0]++; order[1][goal] = next_order[1]++;
    const int dr[4] = {-1, 0, 1, 0}, dc[4] = {0, -1, 0, 1};
    int best = INF_COST, meet = -1;
    while (1) {
        int min_g[2] = {INF_COST, INF_COST};
        for (int side = 0; side < 2; ++side)
            for (int v = 0; v < cells; ++v)
                if (opened[side][v] && g[side][v] < min_g[side]) min_g[side] = g[side][v];
        if (best < INF_COST && (min_g[0] == INF_COST || min_g[1] == INF_COST || min_g[0] + min_g[1] >= best)) break;
        for (int side = 0; side < 2; ++side) {
            int target = side == 0 ? goal : start, chosen = -1, best_f = INF_COST;
            for (int v = 0; v < cells; ++v) if (opened[side][v]) {
                int f = g[side][v] + heuristic(v, target, cols);
                if (chosen < 0 || f < best_f || (f == best_f && order[side][v] < order[side][chosen])) { chosen = v; best_f = f; }
            }
            if (chosen < 0) continue;
            opened[side][chosen] = 0; closed[side][chosen] = 1;
            if (g[1 - side][chosen] < INF_COST && g[side][chosen] + g[1 - side][chosen] < best) { best = g[side][chosen] + g[1 - side][chosen]; meet = chosen; }
            int y = chosen / cols, x = chosen % cols;
            for (int d = 0; d < 4; ++d) {
                int ny = y + dr[d], nx = x + dc[d]; if (ny < 0 || ny >= rows || nx < 0 || nx >= cols) continue;
                int v = ny * cols + nx; if (blocked[v] || closed[side][v]) continue;
                int tentative = g[side][chosen] + 1;
                if (tentative < g[side][v]) {
                    g[side][v] = tentative; parent[side][v] = chosen; opened[side][v] = 1; order[side][v] = next_order[side]++;
                    if (g[1 - side][v] < INF_COST && tentative + g[1 - side][v] < best) { best = tentative + g[1 - side][v]; meet = v; }
                }
            }
        }
        int any = 0; for (int side = 0; side < 2; ++side) for (int v = 0; v < cells; ++v) any |= opened[side][v]; if (!any) break;
    }
    int path[MAX_CELLS], path_len = 0;
    if (meet < 0) { path[path_len++] = start; }
    else {
        int reverse[MAX_CELLS], count = 0; for (int v = meet; v >= 0; v = parent[0][v]) reverse[count++] = v;
        while (count > 0) path[path_len++] = reverse[--count];
        for (int v = parent[1][meet]; v >= 0; v = parent[1][v]) path[path_len++] = v;
    }
    size_t bytes = (1 + 2 * (size_t)path_len) * 8;
    if (!output || capacity < bytes) return -2;
    put_i64(output, 0, path_len);
    for (int i = 0; i < path_len; ++i) { put_i64(output, 1 + 2 * (size_t)i, path[i] / cols); put_i64(output, 2 + 2 * (size_t)i, path[i] % cols); }
    return (int64_t)bytes;
}
