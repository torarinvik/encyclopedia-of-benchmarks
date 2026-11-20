module c_connected_clustered_embedding_condition;

const usz N = 8, M = 18, F = 12, INPUT_MAX = 55;
struct Graph {
    int n, c, m, f, outer_u, outer_v, outer_face;
    int[N] degree, mask;
    int[M] edge_u, edge_v;
    int[N][N] rotation, face_of;
    bool[N][N] adjacent;
}

fn int find_root(int[F]* parent, int x) {
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
}

fn bool is_connected(Graph* g, int mask) {
    int start = -1, expected = 0;
    for (int v = 0; v < g.n; v++) if (((mask >> v) & 1) != 0) {
        if (start < 0) start = v;
        expected++;
    }
    if (expected <= 1) return true;
    bool[N] seen = {};
    int[N] queue = {};
    int head = 0, tail = 0;
    seen[start] = true; queue[tail++] = start;
    while (head < tail) {
        int u = queue[head++];
        for (int v = 0; v < g.n; v++) if (((mask >> v) & 1) != 0 && g.adjacent[u][v] && !seen[v]) {
            seen[v] = true; queue[tail++] = v;
        }
    }
    return tail == expected;
}

fn bool parse(long* input, usz length, Graph* g) {
    if (input == null || length < 4 || length > INPUT_MAX) return false;
    long nraw = input[0], craw = input[1];
    if (nraw < 3 || nraw > N || craw < 0 || craw > nraw - 2) return false;
    g.n = (int)nraw; g.c = (int)craw;
    if (input[2] < 0 || input[2] >= nraw || input[3] < 0 || input[3] >= nraw || input[2] == input[3]) return false;
    g.outer_u = (int)input[2]; g.outer_v = (int)input[3];
    usz offset = 4;
    int degree_sum = 0;
    for (int u = 0; u < g.n; u++) {
        if (offset >= length) return false;
        long d_raw = input[offset++];
        if (d_raw < 1 || d_raw >= nraw || offset + (usz)d_raw > length) return false;
        int d = (int)d_raw;
        g.degree[u] = d; degree_sum += d;
        bool[N] row_seen = {};
        for (int i = 0; i < d; i++) {
            long v_raw = input[offset++];
            if (v_raw < 0 || v_raw >= nraw || v_raw == u || row_seen[(int)v_raw]) return false;
            int v = (int)v_raw;
            row_seen[v] = true; g.rotation[u][i] = v; g.adjacent[u][v] = true;
        }
    }
    if (degree_sum % 2 != 0 || offset + (usz)g.c != length) return false;
    g.m = degree_sum / 2;
    if (g.m < g.n - 1 || g.m > M || !g.adjacent[g.outer_u][g.outer_v]) return false;
    int edge_count = 0;
    for (int u = 0; u < g.n; u++) for (int v = 0; v < g.n; v++) {
        if (g.adjacent[u][v] != g.adjacent[v][u]) return false;
        if (u < v && g.adjacent[u][v]) { g.edge_u[edge_count] = u; g.edge_v[edge_count++] = v; }
    }
    if (edge_count != g.m) return false;
    int full = (1 << g.n) - 1;
    for (int i = 0; i < g.c; i++) {
        long raw = input[offset++];
        if (raw <= 0 || raw >= full) return false;
        int mask = (int)raw, bits = 0;
        for (int v = 0; v < g.n; v++) bits += (mask >> v) & 1;
        if (bits < 2) return false;
        for (int j = 0; j < i; j++) {
            if (g.mask[j] == mask) return false;
            int common = g.mask[j] & mask;
            if (common != 0 && common != g.mask[j] && common != mask) return false;
        }
        g.mask[i] = mask;
        if (!is_connected(g, mask)) return false;
    }
    if (!is_connected(g, full)) return false;
    for (int u = 0; u < N; u++) for (int v = 0; v < N; v++) g.face_of[u][v] = -1;
    g.f = 0;
    for (int e = 0; e < g.m; e++) {
        for (int side = 0; side < 2; side++) {
            int su = side == 0 ? g.edge_u[e] : g.edge_v[e];
            int sv = side == 0 ? g.edge_v[e] : g.edge_u[e];
            if (g.face_of[su][sv] >= 0) continue;
            if (g.f >= F) return false;
            bool[N][N] local = {};
            int u = su, v = sv, steps = 0;
            while (true) {
                if (local[u][v] || g.face_of[u][v] >= 0) return false;
                local[u][v] = true; g.face_of[u][v] = g.f;
                int at = -1;
                for (int i = 0; i < g.degree[v]; i++) if (g.rotation[v][i] == u) { at = i; break; }
                if (at < 0) return false;
                int next = g.rotation[v][(at + 1) % g.degree[v]];
                u = v; v = next;
                if (u == su && v == sv) break;
                if (++steps > 2 * g.m) return false;
            }
            g.f++;
        }
    }
    if (g.f != g.m - g.n + 2) return false;
    for (int u = 0; u < g.n; u++) for (int v = 0; v < g.n; v++)
        if (g.adjacent[u][v] && g.face_of[u][v] < 0) return false;
    g.outer_face = g.face_of[g.outer_u][g.outer_v];
    return g.outer_face >= 0;
}

fn long c_connected_clustered_embedding_condition(long* input, usz length) @export("c_connected_clustered_embedding_condition") {
    Graph g = {};
    if (!parse(input, length, &g)) return -1;
    for (int ci = 0; ci < g.c; ci++) {
        int[F] parent;
        for (int f = 0; f < g.f; f++) parent[f] = f;
        int mask = g.mask[ci];
        for (int e = 0; e < g.m; e++) {
            int u = g.edge_u[e], v = g.edge_v[e];
            if (((mask >> u) & 1) != 0 && ((mask >> v) & 1) != 0) continue;
            parent[find_root(&parent[0], g.face_of[u][v])] = find_root(&parent[0], g.face_of[v][u]);
        }
        int outside = find_root(&parent[0], g.outer_face);
        for (int v = 0; v < g.n; v++) if (((mask >> v) & 1) == 0) {
            bool incident = false;
            for (int u = 0; u < g.n; u++) if (g.adjacent[v][u]) {
                incident = true;
                if (find_root(&parent[0], g.face_of[v][u]) != outside) return 0;
            }
            if (!incident) return -1;
        }
        for (int e = 0; e < g.m; e++) {
            int u = g.edge_u[e], v = g.edge_v[e];
            if (((mask >> u) & 1) != 0 && ((mask >> v) & 1) != 0) continue;
            if (find_root(&parent[0], g.face_of[u][v]) != outside) return 0;
        }
    }
    return 1;
}
