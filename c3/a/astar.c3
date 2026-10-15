module astar;

struct SearchNode { int x; int y; int g; int f; int parent; }
const int ASTAR_MAX_NODES = 256;
const int[8] ASTAR_DX = {-1, -1, -1, 0, 0, 1, 1, 1};
const int[8] ASTAR_DY = {-1, 0, 1, -1, 1, -1, 0, 1};

fn void write_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz shift = 0; shift < 64; shift += 8) output[offset++] = (char)((bits >> shift) & 255);
}

fn long astar(long* input, usz length, char* output, usz capacity) @export("astar") {
    if (input == null || length != 6) return -1;
    long rows_value = input[0], cols_value = input[1];
    long sx_value = input[2], sy_value = input[3], gx_value = input[4], gy_value = input[5];
    if (rows_value < 1 || rows_value > 16 || cols_value < 1 || cols_value > 16 ||
        sx_value < 0 || sx_value >= rows_value || sy_value < 0 || sy_value >= cols_value ||
        gx_value < 0 || gx_value >= rows_value || gy_value < 0 || gy_value >= cols_value) return -1;
    int rows = (int)rows_value, cols = (int)cols_value;
    int sx = (int)sx_value, sy = (int)sy_value, gx = (int)gx_value, gy = (int)gy_value;
    SearchNode[ASTAR_MAX_NODES] nodes;
    int[ASTAR_MAX_NODES] open;
    usz node_count = 1, open_count = 1;
    nodes[0] = {sx, sy, 0, 0, -1};
    open[0] = 0;
    int current = 0;
    bool found = false;
    while (open_count > 0) {
        usz best = 0;
        for (usz i = 1; i < open_count; i++) if (nodes[open[i]].f < nodes[open[best]].f) best = i;
        current = open[best];
        for (usz i = best + 1; i < open_count; i++) open[i - 1] = open[i];
        open_count--;
        if (nodes[current].x == gx && nodes[current].y == gy) { found = true; break; }
        for (usz neighbor = 0; neighbor < 8; neighbor++) {
            int x = nodes[current].x + ASTAR_DX[neighbor];
            int y = nodes[current].y + ASTAR_DY[neighbor];
            if (x < 0 || x >= rows || y < 0 || y >= cols) continue;
            if (node_count >= ASTAR_MAX_NODES || open_count >= ASTAR_MAX_NODES) return -1;
            int g = nodes[current].g + 1;
            int ex = gx - x, ey = gy - y;
            nodes[node_count] = {x, y, g, g + ex * ex + ey * ey, current};
            open[open_count++] = (int)node_count++;
        }
    }
    if (!found) return -1;
    usz path_count = 0;
    for (int cursor = current; cursor >= 0; cursor = nodes[cursor].parent) path_count++;
    usz output_bytes = path_count * 16;
    if (output == null || capacity < output_bytes) return -2;
    usz offset = output_bytes;
    for (int cursor = current; cursor >= 0; cursor = nodes[cursor].parent) {
        offset -= 16;
        write_i64(output, offset, nodes[cursor].x);
        write_i64(output, offset + 8, nodes[cursor].y);
    }
    return output_bytes.long();
}
