module misra_gries_edge_coloring;

const usz MAX_LENGTH = 15;
const long SIGNATURE_BASE = 262144;

fn bool mg_free(long vertex, long color, long vertices, int[36] *edge_at, long[6] *colors) {
    for (long other = 0; other < vertices; other++) {
        int edge = edge_at[vertex * 6 + other];
        if (edge >= 0 && colors[edge] == color) return false;
    }
    return true;
}

fn long misra_gries_edge_coloring(long *input, usz length) @export("misra_gries_edge_coloring") {
    if (input == null || length < 2 || length > MAX_LENGTH) return -1;
    if (input[0] < 1 || input[0] > 6 || input[1] < 0 || input[1] > 6) return -1;
    long vertices = input[0], edge_count = input[1];
    if (length != 2 + 2 * (usz)edge_count) return -1;
    long[6] left = {}, right = {}, degree = {};
    int[36] edge_at;
    for (usz i = 0; i < 36; i++) edge_at[i] = -1;
    for (long edge = 0; edge < edge_count; edge++) {
        long a = input[2 + 2 * edge], b = input[3 + 2 * edge];
        if (a < 0 || b < 0 || a >= vertices || b >= vertices || a == b) return -1;
        long u = a < b ? a : b, v = a < b ? b : a;
        if (edge_at[u * 6 + v] >= 0) return -1;
        left[edge] = u; right[edge] = v;
        edge_at[u * 6 + v] = (int)edge; edge_at[v * 6 + u] = (int)edge;
        degree[u]++; degree[v]++;
    }
    long delta = 0;
    for (long v = 0; v < vertices; v++) if (degree[v] > delta) delta = degree[v];
    long palette = edge_count == 0 ? 0 : delta + 1;
    long[6] colors;
    for (usz i = 0; i < 6; i++) colors[i] = -1;

    for (long edge = 0; edge < edge_count; edge++) {
        long center = left[edge];
        long[6] fan = {};
        long fan_count = 1; fan[0] = right[edge];
        while (true) {
            long tail = fan[fan_count - 1];
            bool extended = false;
            for (long neighbor = 0; neighbor < vertices; neighbor++) {
                int candidate = edge_at[center * 6 + neighbor];
                if (candidate < 0 || colors[candidate] < 0) continue;
                bool present = false;
                for (long i = 0; i < fan_count; i++) if (fan[i] == neighbor) present = true;
                if (present || !mg_free(tail, colors[candidate], vertices, &edge_at, &colors)) continue;
                fan[fan_count++] = neighbor; extended = true; break;
            }
            if (!extended) break;
        }
        long color_c = 0, color_d = 0;
        while (color_c < palette && !mg_free(center, color_c, vertices, &edge_at, &colors)) color_c++;
        while (color_d < palette && !mg_free(fan[fan_count - 1], color_d, vertices, &edge_at, &colors)) color_d++;
        if (color_c >= palette || color_d >= palette) return -1;

        long[6] path = {};
        long path_count = 0, current = center, wanted = color_d;
        bool[6] visited = {}; visited[current] = true;
        for (long step = 0; step < vertices; step++) {
            int path_edge = -1; long next = 0;
            for (long neighbor = 0; neighbor < vertices; neighbor++) {
                int candidate = edge_at[current * 6 + neighbor];
                if (candidate >= 0 && colors[candidate] == wanted) { path_edge = candidate; next = neighbor; break; }
            }
            if (path_edge < 0 || visited[next]) break;
            path[path_count++] = path_edge; visited[next] = true; current = next;
            wanted = wanted == color_d ? color_c : color_d;
        }
        for (long i = 0; i < path_count; i++) colors[path[i]] = colors[path[i]] == color_d ? color_c : color_d;

        long prefix_end = fan_count;
        for (long i = 0; i < fan_count; i++) if (mg_free(fan[i], color_d, vertices, &edge_at, &colors)) { prefix_end = i; break; }
        if (prefix_end == fan_count) return -1;
        long[6] shifted = {};
        for (long i = 0; i < prefix_end; i++) shifted[i] = colors[edge_at[center * 6 + fan[i + 1]]];
        for (long i = 0; i < prefix_end; i++) colors[edge_at[center * 6 + fan[i]]] = shifted[i];
        colors[edge_at[center * 6 + fan[prefix_end]]] = color_d;
    }

    long signature = 0;
    for (long edge = 0; edge < edge_count; edge++) signature |= colors[edge] << (3 * edge);
    return palette * SIGNATURE_BASE + signature;
}
