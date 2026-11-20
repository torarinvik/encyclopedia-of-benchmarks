module cactus_graph_recognition;

const usz MAX_N = 32;
const usz MAX_M = 128;
const usz MAX_INPUT = 259;
const usz MAX_ARCS = 256;

fn long cactus_graph_recognition(long* input, usz length) @export("cactus_graph_recognition") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > 32 || m0 < 0 || m0 > 128) return -1;
    usz n = (usz)n0, m = (usz)m0;
    if (length != 2 + 2 * m) return -1;

    bool[MAX_N * MAX_N] edge_seen = {};
    int[MAX_N] head;
    for (usz u = 0; u < n; u++) head[u] = -1;
    int[MAX_ARCS] arc_to, arc_edge, next_arc;
    usz arc_count = 0;
    for (usz e = 0; e < m; e++) {
        long u0 = input[2 + 2 * e], v0 = input[3 + 2 * e];
        if (u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0) return -1;
        usz u = (usz)u0, v = (usz)v0;
        if (edge_seen[u * MAX_N + v]) return -1;
        edge_seen[u * MAX_N + v] = true;
        edge_seen[v * MAX_N + u] = true;
        arc_to[arc_count] = (int)v; arc_edge[arc_count] = (int)e;
        next_arc[arc_count] = head[u]; head[u] = (int)arc_count++;
        arc_to[arc_count] = (int)u; arc_edge[arc_count] = (int)e;
        next_arc[arc_count] = head[v]; head[v] = (int)arc_count++;
    }

    int[MAX_N] state = {}, parent, parent_edge, depth = {}, cursor, stack, cycle_vertices = {};
    int[MAX_M] cycle_of;
    bool[MAX_M] used = {};
    for (usz u = 0; u < n; u++) { parent[u] = -1; parent_edge[u] = -1; cursor[u] = -1; }
    for (usz e = 0; e < m; e++) cycle_of[e] = -1;
    int cycles = 0;
    bool edge_cactus = true, vertex_cactus = true;

    for (usz root = 0; root < n && edge_cactus; root++) {
        if (state[root] != 0) continue;
        usz top = 1;
        state[root] = 1; cursor[root] = head[root]; stack[0] = (int)root;
        while (top > 0 && edge_cactus) {
            int u = stack[top - 1], arc = cursor[u];
            if (arc < 0) { state[u] = 2; top--; continue; }
            cursor[u] = next_arc[arc];
            int e = arc_edge[arc];
            if (used[e]) continue;
            used[e] = true;
            int v = arc_to[arc];
            if (state[v] == 0) {
                parent[v] = u; parent_edge[v] = e; depth[v] = depth[u] + 1;
                state[v] = 1; cursor[v] = head[v]; stack[top++] = v;
            } else if (state[v] == 1 && depth[v] < depth[u]) {
                int x = u;
                while (x != v) {
                    int tree_edge = parent_edge[x];
                    if (tree_edge < 0 || cycle_of[tree_edge] != -1) { edge_cactus = false; break; }
                    x = parent[x];
                }
                if (!edge_cactus) break;
                x = u;
                cycle_vertices[x]++;
                if (cycle_vertices[x] > 1) vertex_cactus = false;
                while (x != v) {
                    int tree_edge = parent_edge[x];
                    cycle_of[tree_edge] = cycles;
                    x = parent[x];
                    cycle_vertices[x]++;
                    if (cycle_vertices[x] > 1) vertex_cactus = false;
                }
                cycle_of[e] = cycles;
                cycles++;
            }
        }
    }
    if (!edge_cactus) return 0;
    return (long)(4 * cycles + (vertex_cactus ? 2 : 0) + 1);
}
