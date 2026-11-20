module orthogonal_drawing_minimum_bends;

const usz MAX_N = 8, MAX_M = 16, MAX_F = 10, MAX_INPUT = 79;
const usz MAX_NODES = 20, MAX_EDGES = 200;
const long INF = 1152921504606846976;
struct Edge { int from; int to; int reverse; long capacity; long cost; }

fn bool connected(bool[8][8] adjacency, int n, int removed) {
    bool[8] seen = zeroed; int[8] stack; int top = 0, count = 0;
    int start = removed == 0 ? 1 : 0; seen[start] = true; stack[top++] = start;
    while (top > 0) {
        int u = stack[--top]; count++;
        for (int v = 0; v < n; v++) if (v != removed && adjacency[u][v] && !seen[v]) {
            seen[v] = true; stack[top++] = v;
        }
    }
    return count == n - (removed >= 0 ? 1 : 0);
}

fn bool add_arc(Edge[200]* edges, usz* count, int u, int v, long capacity, long cost) {
    if (*count + 2 > MAX_EDGES) return false;
    usz e = *count;
    (*edges)[e] = Edge{u, v, (int)(e + 1), capacity, cost};
    (*edges)[e + 1] = Edge{v, u, (int)e, 0, -cost};
    *count += 2;
    return true;
}

fn long orthogonal_drawing_minimum_bends(long* input, usz length, u8* output, usz capacity)
    @export("orthogonal_drawing_minimum_bends") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long n_raw = input[0], m_raw = input[1], f_raw = input[2], outer_raw = input[3];
    if (n_raw < 3 || n_raw > 8 || m_raw < n_raw || m_raw > 16 || f_raw < 2 || f_raw > 10 ||
        f_raw != m_raw - n_raw + 2 || outer_raw < 0 || outer_raw >= f_raw) return -1;
    int n = (int)n_raw, m = (int)m_raw, f = (int)f_raw, outer = (int)outer_raw;
    bool[8][8] adjacency = zeroed; int[8] degree = zeroed;
    int[16] edge_u, edge_v; long[8][8] uses = zeroed;
    usz cursor = 4;
    for (int e = 0; e < m; e++) {
        if (cursor + 2 > length) return -1;
        long u_raw = input[cursor++], v_raw = input[cursor++];
        if (u_raw < 0 || u_raw >= v_raw || v_raw >= n_raw) return -1;
        int u = (int)u_raw, v = (int)v_raw;
        if (adjacency[u][v] || (e > 0 && (u < edge_u[e-1] || (u == edge_u[e-1] && v <= edge_v[e-1])))) return -1;
        adjacency[u][v] = true; adjacency[v][u] = true; degree[u]++; degree[v]++;
        edge_u[e] = u; edge_v[e] = v;
    }
    for (int v = 0; v < n; v++) if (degree[v] < 2 || degree[v] > 4) return -1;
    int[10][8] face; int[10] width;
    bool[8][8][8] link_adj = zeroed; int[8][8] link_degree = zeroed;
    for (int face_id = 0; face_id < f; face_id++) {
        if (cursor >= length) return -1;
        long width_raw = input[cursor++];
        if (width_raw < 3 || width_raw > n_raw || cursor + (usz)width_raw > length) return -1;
        width[face_id] = (int)width_raw; bool[8] row_seen = zeroed;
        for (int i = 0; i < width[face_id]; i++) {
            long vertex_raw = input[cursor++];
            if (vertex_raw < 0 || vertex_raw >= n_raw || row_seen[(int)vertex_raw]) return -1;
            int vertex = (int)vertex_raw; row_seen[vertex] = true; face[face_id][i] = vertex;
        }
        for (int i = 0; i < width[face_id]; i++) {
            int u = face[face_id][i], v = face[face_id][(i + 1) % width[face_id]];
            if (!adjacency[u][v]) return -1;
            uses[u][v]++;
        }
        for (int i = 0; i < width[face_id]; i++) {
            int center = face[face_id][i];
            int before = face[face_id][(i + width[face_id] - 1) % width[face_id]];
            int after = face[face_id][(i + 1) % width[face_id]];
            if (before == after) return -1;
            link_adj[center][before][after] = true; link_adj[center][after][before] = true;
            link_degree[center][before]++; link_degree[center][after]++;
        }
    }
    if (cursor != length || n - m + f != 2 || !connected(adjacency, n, -1)) return -1;
    for (int v = 0; v < n; v++) if (!connected(adjacency, n, v)) return -1;
    for (int e = 0; e < m; e++) if (uses[edge_u[e]][edge_v[e]] != 1 || uses[edge_v[e]][edge_u[e]] != 1) return -1;
    for (int center = 0; center < n; center++) {
        int start = -1, incident_count = 0;
        for (int neighbor = 0; neighbor < n; neighbor++) {
            if (adjacency[center][neighbor]) {
                if (link_degree[center][neighbor] != 2) return -1;
                if (start < 0) start = neighbor;
                incident_count++;
            } else if (link_degree[center][neighbor] != 0) return -1;
        }
        bool[8] seen = zeroed; int[8] stack; int top = 0, reached = 0;
        seen[start] = true; stack[top++] = start;
        while (top > 0) {
            int neighbor = stack[--top]; reached++;
            for (int other = 0; other < n; other++) if (link_adj[center][neighbor][other] && !seen[other]) {
                seen[other] = true; stack[top++] = other;
            }
        }
        if (reached != incident_count) return -1;
    }
    int[16] face_a, face_b, face_use = zeroed;
    for (int g = 0; g < f; g++) for (int i = 0; i < width[g]; i++) {
        int u = face[g][i], v = face[g][(i + 1) % width[g]];
        int lo = u < v ? u : v, hi = u < v ? v : u, found = -1;
        for (int e = 0; e < m; e++) if (edge_u[e] == lo && edge_v[e] == hi) { found = e; break; }
        if (found < 0 || face_use[found] >= 2) return -1;
        if (face_use[found] == 0) face_a[found] = g; else face_b[found] = g;
        face_use[found]++;
    }
    for (int e = 0; e < m; e++) if (face_use[e] != 2 || face_a[e] == face_b[e]) return -1;
    if (output == null || capacity < 8) return -2;

    int base = n + f, source = base, sink = base + 1, node_count = base + 2;
    Edge[200] edges; usz edge_count = 0; long[18] balance = zeroed;
    for (int v = 0; v < n; v++) balance[v] = 4;
    for (int g = 0; g < f; g++) {
        long d = width[g]; balance[n + g] -= 2 * d + (g == outer ? 4 : -4);
        for (int i = 0; i < width[g]; i++) {
            int v = face[g][i]; balance[v]--; balance[n + g]++;
            if (!add_arc(&edges, &edge_count, v, n + g, 4 * n, 0)) return -1;
        }
    }
    for (int e = 0; e < m; e++) {
        if (!add_arc(&edges, &edge_count, n + face_a[e], n + face_b[e], 4 * n, 1) ||
            !add_arc(&edges, &edge_count, n + face_b[e], n + face_a[e], 4 * n, 1)) return -1;
    }
    long required = 0;
    for (int v = 0; v < base; v++) {
        if (balance[v] > 0) { if (!add_arc(&edges, &edge_count, source, v, balance[v], 0)) return -1; required += balance[v]; }
        else if (balance[v] < 0 && !add_arc(&edges, &edge_count, v, sink, -balance[v], 0)) return -1;
    }
    long[MAX_NODES] potential = zeroed; long flow = 0, total_cost = 0;
    while (flow < required) {
        long[MAX_NODES] dist; int[MAX_NODES] parent; bool[MAX_NODES] used = zeroed;
        for (int v = 0; v < node_count; v++) { dist[v] = INF; parent[v] = -1; }
        dist[source] = 0;
        for (int step = 0; step < node_count; step++) {
            int chosen = -1;
            for (int v = 0; v < node_count; v++) if (!used[v] && dist[v] != INF && (chosen < 0 || dist[v] < dist[chosen])) chosen = v;
            if (chosen < 0) break;
            used[chosen] = true;
            for (usz e = 0; e < edge_count; e++) if (edges[e].from == chosen && edges[e].capacity > 0) {
                int v = edges[e].to; long candidate = dist[chosen] + edges[e].cost + potential[chosen] - potential[v];
                if (!used[v] && candidate < dist[v]) { dist[v] = candidate; parent[v] = (int)e; }
            }
        }
        if (dist[sink] == INF) return -1;
        for (int v = 0; v < node_count; v++) if (dist[v] != INF) potential[v] += dist[v];
        long amount = required - flow, path_cost = 0;
        for (int v = sink; v != source; v = edges[parent[v]].from) {
            if (parent[v] < 0) return -1;
            if (amount > edges[parent[v]].capacity) amount = edges[parent[v]].capacity;
            path_cost += edges[parent[v]].cost;
        }
        for (int v = sink; v != source; v = edges[parent[v]].from) {
            int e = parent[v]; edges[e].capacity -= amount; edges[edges[e].reverse].capacity += amount;
        }
        flow += amount; total_cost += amount * path_cost;
    }
    ulong bits = (ulong)total_cost;
    for (usz i = 0; i < 8; i++) output[i] = (u8)(bits >> (8 * i));
    return 8;
}
