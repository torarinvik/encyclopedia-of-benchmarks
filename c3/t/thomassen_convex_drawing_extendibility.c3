module thomassen_convex_drawing_extendibility;

const usz N = 8, M = 18, F = 12, INPUT_MAX = 93;
const usz FLOW_NODES = 18, STATES = 256;

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

fn bool three_outer_paths(bool[8][8] adjacency, bool[8] outer, int n, int root) {
    int[18][18] residual = zeroed;
    int source = 2 * n, sink = source + 1, nodes = sink + 1;
    for (int v = 0; v < n; v++) if (v != root) residual[2*v][2*v+1] = 1;
    for (int u = 0; u < n; u++) for (int v = u + 1; v < n; v++) if (adjacency[u][v]) {
        if (u == root) residual[source][2*v]++;
        else if (v == root) residual[source][2*u]++;
        else { residual[2*u+1][2*v]++; residual[2*v+1][2*u]++; }
    }
    for (int v = 0; v < n; v++) if (outer[v] && v != root) residual[2*v+1][sink]++;
    for (int flow = 0; flow < 3; flow++) {
        int[18] parent; int[18] queue; int head = 0, tail = 0;
        for (int v = 0; v < nodes; v++) parent[v] = -1;
        parent[source] = source; queue[tail++] = source;
        while (head < tail && parent[sink] < 0) {
            int u = queue[head++];
            for (int v = 0; v < nodes; v++) if (residual[u][v] > 0 && parent[v] < 0) {
                parent[v] = u; queue[tail++] = v;
                if (v == sink) break;
            }
        }
        if (parent[sink] < 0) return false;
        for (int v = sink; v != source; v = parent[v]) { int u = parent[v]; residual[u][v]--; residual[v][u]++; }
    }
    return true;
}

fn bool condition_three(bool[8][8] inner, int[8] degree, int n) {
    int[256] mask_size = zeroed;
    for (int mask = 1; mask < (1 << n); mask++) mask_size[mask] = mask_size[mask >> 1] + (mask & 1);
    for (int start = 0; start < n; start++) {
        u8[256][8] dp;
        for (int mask = 0; mask < STATES; mask++) for (int last = 0; last < N; last++) dp[mask][last] = 255;
        dp[1 << start][start] = (u8)(degree[start] >= 3 ? 1 : 0);
        for (int mask = 0; mask < (1 << n); mask++) {
            if ((mask & (1 << start)) == 0) continue;
            for (int last = start; last < n; last++) {
                u8 used = dp[mask][last];
                if (used == 255) continue;
                if (mask_size[mask] >= 3 && inner[last][start] && used < 3) return false;
                for (int next = start + 1; next < n; next++) {
                    int bit = 1 << next;
                    if ((mask & bit) != 0 || !inner[last][next]) continue;
                    int candidate = used + (degree[next] >= 3 ? 1 : 0), next_mask = mask | bit;
                    if (candidate < dp[next_mask][next]) dp[next_mask][next] = (u8)candidate;
                }
            }
        }
    }
    return true;
}

fn long thomassen_convex_drawing_extendibility(long* input, usz length)
    @export("thomassen_convex_drawing_extendibility") {
    if (input == null || length < 5 || length > INPUT_MAX) return -1;
    long n0 = input[0], m0 = input[1], f0 = input[2], outer0 = input[3], side0 = input[4];
    if (n0 < 3 || n0 > N || m0 < n0 || m0 > M || m0 > 3*n0-6 || f0 < 2 || f0 > F ||
        f0 != m0-n0+2 || outer0 < 0 || outer0 >= f0 || side0 < 3 || side0 > n0) return -1;
    int n = (int)n0, m = (int)m0, f = (int)f0, outer_id = (int)outer0, side_count = (int)side0;
    bool[8][8] adjacency = zeroed; int[18] edge_u, edge_v;
    for (int e = 0; e < m; e++) {
        usz p = 5 + (usz)(2*e); if (p + 1 >= length) return -1;
        long u0 = input[p], v0 = input[p+1];
        if (u0 < 0 || u0 >= v0 || v0 >= n) return -1;
        int u = (int)u0, v = (int)v0;
        if (adjacency[u][v] || (e > 0 && (u < edge_u[e-1] || (u == edge_u[e-1] && v <= edge_v[e-1])))) return -1;
        adjacency[u][v] = true; adjacency[v][u] = true; edge_u[e] = u; edge_v[e] = v;
    }
    int[12][8] faces; int[12] width; int[8][8] darts = zeroed;
    usz cursor = 5 + (usz)(2*m);
    for (int g = 0; g < f; g++) {
        if (cursor >= length) return -1;
        long w0 = input[cursor++]; if (w0 < 3 || w0 > n || cursor + (usz)w0 > length) return -1;
        width[g] = (int)w0; bool[8] row = zeroed;
        for (int i = 0; i < width[g]; i++) {
            long x0 = input[cursor++]; if (x0 < 0 || x0 >= n || row[(int)x0]) return -1;
            int x = (int)x0; row[x] = true; faces[g][i] = x;
        }
        for (int i = 0; i < width[g]; i++) {
            int u = faces[g][i], v = faces[g][(i+1)%width[g]];
            if (!adjacency[u][v]) return -1;
            darts[u][v]++;
        }
    }
    if (cursor + (usz)side_count != length) return -1;
    int[8] apex;
    for (int i = 0; i < side_count; i++) {
        long pos = input[cursor++];
        if (pos < 0 || pos >= width[outer_id] || (i > 0 && pos <= apex[i-1])) return -1;
        apex[i] = (int)pos;
    }
    for (int e = 0; e < m; e++) if (darts[edge_u[e]][edge_v[e]] != 1 || darts[edge_v[e]][edge_u[e]] != 1) return -1;
    if (!connected(adjacency, n, -1)) return -1;
    for (int v = 0; v < n; v++) if (!connected(adjacency, n, v)) return -1;

    bool[8][8][8] link_adj = zeroed; int[8][8] link_degree = zeroed;
    for (int g = 0; g < f; g++) for (int i = 0; i < width[g]; i++) {
        int center = faces[g][i], before = faces[g][(i+width[g]-1)%width[g]], after = faces[g][(i+1)%width[g]];
        if (before == after) return -1;
        link_adj[center][before][after] = true; link_adj[center][after][before] = true;
        link_degree[center][before]++; link_degree[center][after]++;
    }
    for (int center = 0; center < n; center++) {
        int seed = -1, incident = 0;
        for (int v = 0; v < n; v++) {
            if (adjacency[center][v]) { if (link_degree[center][v] != 2) return -1; if (seed < 0) seed = v; incident++; }
            else if (link_degree[center][v] != 0) return -1;
        }
        if (seed < 0) return -1;
        bool[8] seen = zeroed; int[8] stack; int top = 0, reached = 0;
        seen[seed] = true; stack[top++] = seed;
        while (top > 0) { int v = stack[--top]; reached++;
            for (int w = 0; w < n; w++) if (link_adj[center][v][w] && !seen[w]) { seen[w] = true; stack[top++] = w; }
        }
        if (reached != incident) return -1;
    }
    bool[8] outer_v = zeroed; bool[8][8] outer_e = zeroed;
    for (int i = 0; i < width[outer_id]; i++) {
        int u = faces[outer_id][i], v = faces[outer_id][(i+1)%width[outer_id]];
        outer_v[u] = true; outer_e[u][v] = true; outer_e[v][u] = true;
    }
    int[18] fa, fb, fc = zeroed;
    for (int g = 0; g < f; g++) for (int i = 0; i < width[g]; i++) {
        int u = faces[g][i], v = faces[g][(i+1)%width[g]], lo = u < v ? u : v, hi = u < v ? v : u, found = -1;
        for (int e = 0; e < m; e++) if (edge_u[e] == lo && edge_v[e] == hi) { found = e; break; }
        if (found < 0 || fc[found] >= 2) return -1;
        if (fc[found]++ == 0) fa[found] = g; else fb[found] = g;
    }
    for (int e = 0; e < m; e++) if (fc[e] != 2 || fa[e] == fb[e]) return -1;
    bool[8][8] sides = zeroed;
    for (int s = 0; s < side_count; s++) {
        int at = apex[s], end = apex[(s+1)%side_count];
        while (true) { sides[s][faces[outer_id][at]] = true; if (at == end) break; at = (at+1)%width[outer_id]; }
    }
    int[8] degree = zeroed;
    for (int u = 0; u < n; u++) for (int v = 0; v < n; v++) if (adjacency[u][v]) degree[u]++;
    for (int root = 0; root < n; root++)
        if (!outer_v[root] && degree[root] >= 3 && !three_outer_paths(adjacency, outer_v, n, root)) return 0;
    bool[8] seen_inner = zeroed;
    for (int seed = 0; seed < n; seed++) if (!outer_v[seed] && !seen_inner[seed]) {
        bool[8] border = zeroed; int[8] stack; int top = 0; seen_inner[seed] = true; stack[top++] = seed;
        while (top > 0) { int u = stack[--top]; for (int v = 0; v < n; v++) if (adjacency[u][v]) {
            if (outer_v[v]) border[v] = true; else if (!seen_inner[v]) { seen_inner[v] = true; stack[top++] = v; }
        }}
        for (int s = 0; s < side_count; s++) { bool nonempty = false, contained = true;
            for (int v = 0; v < n; v++) if (border[v]) { nonempty = true; if (!sides[s][v]) contained = false; }
            if (nonempty && contained) return 0;
        }
    }
    for (int e = 0; e < m; e++) if (!outer_e[edge_u[e]][edge_v[e]])
        for (int s = 0; s < side_count; s++) if (sides[s][edge_u[e]] && sides[s][edge_v[e]]) return 0;
    bool[8][8] inner = zeroed;
    for (int e = 0; e < m; e++) if (!outer_e[edge_u[e]][edge_v[e]]) { inner[edge_u[e]][edge_v[e]] = true; inner[edge_v[e]][edge_u[e]] = true; }
    return condition_three(inner, degree, n) ? 1 : 0;
}
