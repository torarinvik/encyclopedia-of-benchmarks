module graph_coloring_backtracking;

const MAX_VERTICES = 64;
const MAX_EDGES = 2016;

fn bool color_vertex(usz vertex, usz count, bool* adjacency, long* colors) {
    if (vertex == count) return true;
    for (usz color = 1; color <= count; color++) {
        bool safe = true;
        for (usz neighbor = 0; neighbor < count; neighbor++) {
            if (adjacency[vertex * MAX_VERTICES + neighbor] && colors[neighbor] == (long)color) {
                safe = false;
                break;
            }
        }
        if (!safe) continue;
        colors[vertex] = (long)color;
        if (color_vertex(vertex + 1, count, adjacency, colors)) return true;
        colors[vertex] = 0;
    }
    return false;
}

fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long graph_coloring_backtracking(long* input, usz length, char* output, usz capacity)
    @export("graph_coloring_backtracking") {
    if (input == null || length < 2) return -1;
    long n_value = input[0];
    long m_value = input[1];
    if (n_value < 0 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES ||
        length != 2 + 2 * (usz)m_value) return -1;
    usz n = (usz)n_value;
    usz m = (usz)m_value;
    bool[MAX_VERTICES * MAX_VERTICES] adjacency;
    long[MAX_VERTICES] colors;
    for (usz index = 0; index < MAX_VERTICES * MAX_VERTICES; index++) adjacency[index] = false;
    for (usz index = 0; index < MAX_VERTICES; index++) colors[index] = 0;
    for (usz edge = 0; edge < m; edge++) {
        long u_value = input[2 + 2 * edge];
        long v_value = input[3 + 2 * edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value) {
            return -1;
        }
        usz u = (usz)u_value;
        usz v = (usz)v_value;
        adjacency[u * MAX_VERTICES + v] = true;
        adjacency[v * MAX_VERTICES + u] = true;
    }
    if (!color_vertex(0, n, &adjacency[0], &colors[0])) return -1;
    long colors_used = 0;
    for (usz vertex = 0; vertex < n; vertex++) if (colors[vertex] > colors_used) colors_used = colors[vertex];
    long[MAX_VERTICES + 2] packed;
    packed[0] = n_value;
    for (usz vertex = 0; vertex < n; vertex++) packed[vertex + 1] = colors[vertex];
    packed[n + 1] = colors_used;
    usz used = n + 2;
    usz required = used * 8;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < used; index++) put_i64(output, index * 8, packed[index]);
    return (long)required;
}
