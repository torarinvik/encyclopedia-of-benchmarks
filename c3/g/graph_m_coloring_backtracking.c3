module graph_m_coloring_backtracking;

const MAX_VERTICES = 12;

fn bool assign_colors(long* input, usz count, usz max_colors, usz vertex, long* colors) {
    if (vertex == count) return true;
    for (usz color = 0; color < max_colors; color++) {
        bool safe = true;
        for (usz neighbor = 0; neighbor < count; neighbor++) {
            if (input[2 + vertex * count + neighbor] == 1 && colors[neighbor] == (long)color) {
                safe = false;
                break;
            }
        }
        if (!safe) continue;
        colors[vertex] = (long)color;
        if (assign_colors(input, count, max_colors, vertex + 1, colors)) return true;
        colors[vertex] = -1;
    }
    return false;
}

fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long graph_m_coloring_backtracking(long* input, usz length, char* output, usz capacity)
    @export("graph_m_coloring_backtracking") {
    if (input == null || length < 2) return -1;
    long n_value = input[0];
    long colors_value = input[1];
    if (n_value < 0 || n_value > MAX_VERTICES || colors_value < 0 || colors_value > MAX_VERTICES) return -1;
    usz n = (usz)n_value;
    usz max_colors = (usz)colors_value;
    if (length != 2 + n * n) return -1;
    for (usz row = 0; row < n; row++) {
        if (input[2 + row * n + row] != 0) return -1;
        for (usz column = 0; column < n; column++) {
            long cell = input[2 + row * n + column];
            if ((cell != 0 && cell != 1) || cell != input[2 + column * n + row]) return -1;
        }
    }
    long[MAX_VERTICES] colors;
    for (usz vertex = 0; vertex < n; vertex++) colors[vertex] = -1;
    if (!assign_colors(&input[0], n, max_colors, 0, &colors[0])) return 0;
    usz required = n * 8;
    if (required == 0) return 0;
    if (output == null || capacity < required) return -2;
    for (usz vertex = 0; vertex < n; vertex++) put_i64(output, vertex * 8, colors[vertex]);
    return (long)required;
}
