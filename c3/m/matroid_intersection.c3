module matroid_intersection;

const usz MAX_VERTICES = 10;
const usz MAX_EDGES = 20;
const usz MAX_COLORS = 8;

fn bool mi_is_forest(long* input, usz vertices, usz edges, usz edge_start,
                     bool* chosen, long removed, long added) {
    long[MAX_VERTICES] parent;
    for (usz v = 0; v < vertices; v++) parent[v] = (long)v;
    for (usz edge = 0; edge < edges; edge++) {
        if ((long)edge != added && (!chosen[edge] || (long)edge == removed)) continue;
        usz a = (usz)input[edge_start + 3 * edge];
        usz b = (usz)input[edge_start + 3 * edge + 1];
        while ((usz)parent[a] != a) a = (usz)parent[a];
        while ((usz)parent[b] != b) b = (usz)parent[b];
        if (a == b) return false;
        parent[b] = (long)a;
    }
    return true;
}

fn bool mi_within_quotas(long* input, usz colors, usz edges,
                         usz edge_start, bool* chosen,
                         long removed, long added) {
    long[MAX_COLORS] counts = zeroed;
    for (usz edge = 0; edge < edges; edge++) {
        if ((long)edge != added && (!chosen[edge] || (long)edge == removed)) continue;
        usz color = (usz)input[edge_start + 3 * edge + 2];
        counts[color]++;
        if (counts[color] > input[3 + color]) return false;
    }
    return true;
}

fn long matroid_intersection(long* input, usz length) @export("matroid_intersection") {
    if (input == null || length < 4 || length > 72) return -1;
    long vertices_value = input[0], edges_value = input[1], colors_value = input[2];
    if (vertices_value < 1 || vertices_value > (long)MAX_VERTICES
            || edges_value < 0 || edges_value > (long)MAX_EDGES
            || colors_value < 1 || colors_value > (long)MAX_COLORS) return -1;
    usz vertices = (usz)vertices_value, edges = (usz)edges_value, colors = (usz)colors_value;
    if (length != 3 + colors + 3 * edges) return -1;
    for (usz color = 0; color < colors; color++) {
        if (input[3 + color] < 0 || input[3 + color] > (long)MAX_EDGES) return -1;
    }
    usz edge_start = 3 + colors;
    for (usz edge = 0; edge < edges; edge++) {
        long u = input[edge_start + 3 * edge];
        long v = input[edge_start + 3 * edge + 1];
        long color = input[edge_start + 3 * edge + 2];
        if (u < 0 || u >= vertices_value || v < 0 || v >= vertices_value
                || color < 0 || color >= colors_value) return -1;
    }

    bool[MAX_EDGES] chosen = {};
    for (;;) {
        long[MAX_EDGES] predecessor;
        long[MAX_EDGES] queue;
        for (usz edge = 0; edge < edges; edge++) predecessor[edge] = -2;
        usz head = 0, tail = 0;
        for (usz edge = 0; edge < edges; edge++) {
            if (!chosen[edge] && mi_is_forest(input, vertices, edges, edge_start,
                                              &chosen[0], -1, (long)edge)) {
                predecessor[edge] = -1;
                queue[tail++] = (long)edge;
            }
        }
        long terminal = -1;
        while (head < tail && terminal < 0) {
            usz current = (usz)queue[head++];
            if (!chosen[current]) {
                if (mi_within_quotas(input, colors, edges, edge_start,
                                     &chosen[0], -1, (long)current)) {
                    terminal = (long)current;
                    break;
                }
                for (usz inside = 0; inside < edges; inside++) {
                    if (chosen[inside] && predecessor[inside] == -2
                            && mi_within_quotas(input, colors, edges, edge_start,
                                                &chosen[0], (long)inside, (long)current)) {
                        predecessor[inside] = (long)current;
                        queue[tail++] = (long)inside;
                    }
                }
            } else {
                for (usz outside = 0; outside < edges; outside++) {
                    if (!chosen[outside] && predecessor[outside] == -2
                            && mi_is_forest(input, vertices, edges, edge_start,
                                            &chosen[0], (long)current, (long)outside)) {
                        predecessor[outside] = (long)current;
                        queue[tail++] = (long)outside;
                    }
                }
            }
        }
        if (terminal < 0) break;
        long node = terminal;
        while (node >= 0) {
            chosen[(usz)node] = !chosen[(usz)node];
            node = predecessor[(usz)node];
        }
    }
    long answer = 0;
    for (usz edge = 0; edge < edges; edge++) if (chosen[edge]) answer++;
    return answer;
}
