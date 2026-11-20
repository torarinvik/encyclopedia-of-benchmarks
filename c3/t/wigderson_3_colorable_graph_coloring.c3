module wigderson_3_colorable_graph_coloring;

const usz MAX_VERTICES = 32;
const usz MAX_EDGES = 128;
const usz MAX_INPUT = 2 + 2 * MAX_EDGES;

fn long wigderson_3_colorable_graph_coloring(long* input, usz length,
        uint8* output, usz capacity) @export("wigderson_3_colorable_graph_coloring") {
    if (input == null || length < 2 || length > MAX_INPUT + 1) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_VERTICES ||
            input[1] < 0 || input[1] > (long)MAX_EDGES) return -1;
    usz n = (usz)input[0];
    usz m = (usz)input[1];
    if (length != 2 + 2 * m) return -1;

    bool[MAX_VERTICES][MAX_VERTICES] adjacent = zeroed;
    for (usz e = 0; e < m; e += 1) {
        long ru = input[2 + 2 * e];
        long rv = input[3 + 2 * e];
        if (ru < 0 || rv <= ru || (usz)rv >= n) return -1;
        usz u = (usz)ru;
        usz v = (usz)rv;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = true;
        adjacent[v][u] = true;
    }

    bool[MAX_VERTICES] active = zeroed;
    uint8[MAX_VERTICES] color = zeroed;
    for (usz v = 0; v < n; v += 1) active[v] = true;
    usz threshold = 0;
    while ((threshold + 1) * (threshold + 1) <= n) threshold += 1;
    long next_color = 1;

    while (true) {
        usz chosen = n;
        usz maximum_degree = 0;
        for (usz v = 0; v < n; v += 1) {
            if (!active[v]) continue;
            usz degree = 0;
            for (usz w = 0; w < n; w += 1)
                if (active[w] && adjacent[v][w]) degree += 1;
            if (chosen == n || degree > maximum_degree) {
                chosen = v;
                maximum_degree = degree;
            }
        }
        if (chosen == n || maximum_degree < threshold) break;

        bool[MAX_VERTICES] in_neighborhood = zeroed;
        int8[MAX_VERTICES] side = zeroed;
        usz[MAX_VERTICES] queue = zeroed;
        for (usz v = 0; v < n; v += 1) {
            side[v] = -1;
            in_neighborhood[v] = active[v] && adjacent[chosen][v];
        }
        for (usz root = 0; root < n; root += 1) {
            if (!in_neighborhood[root] || side[root] >= 0) continue;
            usz head = 0;
            usz tail = 0;
            side[root] = 0;
            queue[tail] = root;
            tail += 1;
            while (head < tail) {
                usz u = queue[head];
                head += 1;
                for (usz v = 0; v < n; v += 1) {
                    if (!in_neighborhood[v] || !adjacent[u][v]) continue;
                    if (side[v] < 0) {
                        side[v] = (int8)(1 - side[u]);
                        queue[tail] = v;
                        tail += 1;
                    } else if (side[v] == side[u]) return -1;
                }
            }
        }
        for (usz v = 0; v < n; v += 1)
            if (in_neighborhood[v]) color[v] = (uint8)(next_color + side[v]);
        color[chosen] = (uint8)(next_color + 2);
        active[chosen] = false;
        for (usz v = 0; v < n; v += 1)
            if (adjacent[chosen][v]) active[v] = false;
        next_color += 2;
    }

    for (usz v = 0; v < n; v += 1) {
        if (!active[v]) continue;
        bool[MAX_VERTICES + 2] used = zeroed;
        for (usz w = 0; w < n; w += 1)
            if (adjacent[v][w] && color[w] > 0) used[color[w]] = true;
        long candidate = next_color;
        while (candidate < (long)(MAX_VERTICES + 2) && used[candidate]) candidate += 1;
        if (candidate >= (long)(MAX_VERTICES + 2)) return -1;
        color[v] = (uint8)candidate;
    }

    uint8 palette = 0;
    for (usz v = 0; v < n; v += 1) if (color[v] > palette) palette = color[v];
    usz output_bytes = n + 1;
    if (output == null || capacity < output_bytes) return -2;
    output[0] = palette;
    for (usz v = 0; v < n; v += 1) output[v + 1] = color[v];
    return (long)output_bytes;
}
