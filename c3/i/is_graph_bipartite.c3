module is_graph_bipartite;

const usz MAX_VERTICES = 64;
const usz MAX_EDGES = 256;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES;
const long INVALID_RESULT = -1;

fn long is_graph_bipartite(long* values, usz length) @export("is_graph_bipartite") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long vertex_count_raw = values[0];
    long edge_count_raw = values[1];
    if (vertex_count_raw < 0 || vertex_count_raw > (long)MAX_VERTICES ||
        edge_count_raw < 0 || edge_count_raw > (long)MAX_EDGES ||
        length != 2 + 2 * (usz)edge_count_raw) return INVALID_RESULT;
    usz vertex_count = (usz)vertex_count_raw;
    usz edge_count = (usz)edge_count_raw;

    int head[64];
    int arc_to[512];
    int arc_next[512];
    int side[64];
    int queue[64];
    for (usz vertex = 0; vertex < vertex_count; vertex++) {
        head[vertex] = -1;
        side[vertex] = -1;
    }
    int arc_count = 0;
    for (usz edge = 0; edge < edge_count; edge++) {
        long u_raw = values[2 + 2 * edge];
        long v_raw = values[3 + 2 * edge];
        if (u_raw < 1 || u_raw > vertex_count_raw || v_raw < 1 || v_raw > vertex_count_raw)
            return INVALID_RESULT;
        int u = (int)(u_raw - 1);
        int v = (int)(v_raw - 1);
        arc_to[arc_count] = v; arc_next[arc_count] = head[u]; head[u] = arc_count++;
        arc_to[arc_count] = u; arc_next[arc_count] = head[v]; head[v] = arc_count++;
    }

    bool bipartite = true;
    for (usz start = 0; start < vertex_count; start++) {
        if (side[start] != -1) continue;
        usz queue_head = 0;
        usz queue_tail = 1;
        queue[0] = (int)start;
        side[start] = 0;
        while (queue_head < queue_tail) {
            int current = queue[queue_head++];
            for (int arc = head[current]; arc != -1; arc = arc_next[arc]) {
                int neighbor = arc_to[arc];
                if (side[neighbor] == -1) {
                    side[neighbor] = side[current] ^ 1;
                    queue[queue_tail++] = neighbor;
                } else if (side[neighbor] == side[current]) {
                    bipartite = false;
                }
            }
        }
    }
    return bipartite ? 1 : 0;
}
