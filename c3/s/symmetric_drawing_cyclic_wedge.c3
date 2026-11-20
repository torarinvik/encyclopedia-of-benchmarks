module symmetric_drawing_cyclic_wedge;

const usz N = 8, M = 18, F = 12, INPUT_MAX = 55, OUTPUT_MAX = 128;

struct Graph {
    int n, k, b, m, f, center, outer_id;
    int[N] outer, degree, permutation;
    int[M] edge_u, edge_v;
    int[F] face_len;
    int[F][N] face;
    int[N][N] rotation, dart_face;
    bool[N][N] adjacent;
}

fn bool connected_without(Graph* g, int removed_a, int removed_b) {
    int start = -1, expected = 0;
    for (int v = 0; v < g.n; v++) if (v != removed_a && v != removed_b) {
        if (start < 0) start = v;
        expected++;
    }
    if (expected <= 1) return true;
    bool[N] seen = {};
    int[N] stack = {};
    int top = 1, count = 0;
    seen[start] = true; stack[0] = start;
    while (top > 0) {
        int u = stack[--top]; count++;
        for (int v = 0; v < g.n; v++) if (v != removed_a && v != removed_b &&
            g.adjacent[u][v] && !seen[v]) {
            seen[v] = true; stack[top++] = v;
        }
    }
    return count == expected;
}

fn int face_walk(Graph* g, int first, int second, int[2 * M] cycle) {
    bool[N][N] seen = {};
    int u = first, v = second, length = 0;
    for (int step = 0; step < 2 * g.m; step++) {
        if (!g.adjacent[u][v] || seen[u][v]) return -1;
        seen[u][v] = true; cycle[length++] = u;
        int at = -1;
        for (int i = 0; i < g.degree[v]; i++) if (g.rotation[v][i] == u) at = i;
        if (at < 0) return -1;
        int next = g.rotation[v][(at + 1) % g.degree[v]];
        u = v; v = next;
        if (u == first && v == second) return length;
    }
    return -1;
}

fn bool cyclic_equal(int[N] a, int[N] b, int length) {
    for (int shift = 0; shift < length; shift++) {
        bool equal = true;
        for (int i = 0; i < length; i++) if (a[i] != b[(i + shift) % length]) equal = false;
        if (equal) return true;
    }
    return false;
}

fn bool parse(long* input, usz length, Graph* g) {
    if (input == null || length < 3 || length > INPUT_MAX) return false;
    if (input[0] < 4 || input[0] > N || input[1] < 3 || input[1] > N ||
        (input[0] - 1) % input[1] != 0 ||
        input[2] < input[1] || input[2] > input[0] || input[2] % input[1] != 0) return false;
    g.n = (int)input[0]; g.k = (int)input[1]; g.b = (int)input[2];
    usz offset = 3;
    if (offset + (usz)g.b > length) return false;
    bool[N] outer_seen = {};
    for (int i = 0; i < g.b; i++) {
        long raw = input[offset++];
        if (raw < 0 || raw >= g.n || outer_seen[(int)raw]) return false;
        g.outer[i] = (int)raw; outer_seen[(int)raw] = true;
    }
    int degree_sum = 0;
    for (int u = 0; u < g.n; u++) {
        if (offset >= length) return false;
        long raw_degree = input[offset++];
        if (raw_degree < 3 || raw_degree >= g.n || offset + (usz)raw_degree > length) return false;
        int d = (int)raw_degree; g.degree[u] = d; degree_sum += d;
        bool[N] row_seen = {};
        for (int i = 0; i < d; i++) {
            long raw = input[offset++];
            if (raw < 0 || raw >= g.n || raw == u || row_seen[(int)raw]) return false;
            int v = (int)raw; row_seen[v] = true; g.rotation[u][i] = v; g.adjacent[u][v] = true;
        }
    }
    if (offset + (usz)g.n != length || degree_sum % 2 != 0) return false;
    bool[N] perm_seen = {};
    for (int u = 0; u < g.n; u++) {
        long raw = input[offset++];
        if (raw < 0 || raw >= g.n || perm_seen[(int)raw]) return false;
        g.permutation[u] = (int)raw; perm_seen[(int)raw] = true;
    }
    g.m = degree_sum / 2;
    if (g.m < g.n || g.m > 3 * g.n - 6 || g.m > M) return false;
    int edge_count = 0;
    for (int u = 0; u < g.n; u++) for (int v = 0; v < g.n; v++) {
        if (g.adjacent[u][v] != g.adjacent[v][u]) return false;
        if (u < v && g.adjacent[u][v]) { g.edge_u[edge_count] = u; g.edge_v[edge_count++] = v; }
    }
    if (edge_count != g.m || !connected_without(g, -1, -1)) return false;
    for (int u = 0; u < g.n; u++) {
        if (!connected_without(g, u, -1)) return false;
        for (int v = u + 1; v < g.n; v++) if (!connected_without(g, u, v)) return false;
    }
    for (int u = 0; u < N; u++) for (int v = 0; v < N; v++) g.dart_face[u][v] = -1;
    for (int e = 0; e < g.m; e++) for (int direction = 0; direction < 2; direction++) {
        int u = direction == 0 ? g.edge_u[e] : g.edge_v[e];
        int v = direction == 0 ? g.edge_v[e] : g.edge_u[e];
        if (g.dart_face[u][v] >= 0) continue;
        if (g.f >= F) return false;
        int[2 * M] cycle = {};
        int face_length = face_walk(g, u, v, cycle);
        if (face_length < 3 || face_length > g.n) return false;
        bool[N] face_seen = {};
        for (int i = 0; i < face_length; i++) {
            int a = cycle[i], b = cycle[(i + 1) % face_length];
            if (face_seen[a] || g.dart_face[a][b] >= 0) return false;
            face_seen[a] = true;
        }
        for (int i = 0; i < face_length; i++) {
            int a = cycle[i], b = cycle[(i + 1) % face_length];
            g.face[g.f][i] = a; g.dart_face[a][b] = g.f;
        }
        g.face_len[g.f++] = face_length;
    }
    if (g.f != g.m - g.n + 2) return false;
    g.outer_id = -1;
    for (int f = 0; f < g.f; f++) if (g.face_len[f] == g.b && cyclic_equal(g.outer, g.face[f], g.b)) g.outer_id = f;
    if (g.outer_id < 0) return false;
    int fixed_count = 0;
    for (int v = 0; v < g.n; v++) if (g.permutation[v] == v) { g.center = v; fixed_count++; }
    if (fixed_count != 1 || outer_seen[g.center]) return false;
    for (int v = 0; v < g.n; v++) if (v != g.center) {
        int current = g.permutation[v], orbit_length = 1;
        while (current != v && orbit_length <= g.k) { current = g.permutation[current]; orbit_length++; }
        if (current != v || orbit_length != g.k) return false;
    }
    int[N] power = {};
    for (int v = 0; v < g.n; v++) power[v] = v;
    for (int step = 1; step <= g.k; step++) {
        int[N] next = {};
        bool identity = true;
        for (int v = 0; v < g.n; v++) { next[v] = g.permutation[power[v]]; if (next[v] != v) identity = false; }
        if (identity != (step == g.k)) return false;
        power = next;
    }
    for (int u = 0; u < g.n; u++) {
        int image = g.permutation[u];
        for (int v = 0; v < g.n; v++) if (g.adjacent[u][v] != g.adjacent[image][g.permutation[v]]) return false;
        bool row_ok = false;
        for (int shift = 0; shift < g.degree[image]; shift++) {
            bool equal = true;
            for (int i = 0; i < g.degree[u]; i++)
                if (g.permutation[g.rotation[u][i]] != g.rotation[image][(i + shift) % g.degree[image]]) equal = false;
            if (equal) row_ok = true;
        }
        if (!row_ok) return false;
    }
    int shift = g.b / g.k;
    for (int i = 0; i < g.b; i++) if (g.permutation[g.outer[i]] != g.outer[(i + shift) % g.b]) return false;
    return true;
}

fn int solve(Graph* g, long[29] words) {
    int[N] distance = {}; for (int v = 0; v < N; v++) distance[v] = -1;
    int[N] queue = {}; int head = 0, tail = 1;
    distance[g.center] = 0; queue[0] = g.center;
    while (head < tail) {
        int u = queue[head++];
        for (int v = 0; v < g.n; v++) if (g.adjacent[u][v] && distance[v] < 0) {
            distance[v] = distance[u] + 1; queue[tail++] = v;
        }
    }
    int endpoint = -1;
    for (int i = 0; i < g.b; i++) {
        int v = g.outer[i];
        if (endpoint < 0 || distance[v] < distance[endpoint] || (distance[v] == distance[endpoint] && v < endpoint)) endpoint = v;
    }
    if (endpoint < 0 || distance[endpoint] <= 0) return -1;
    int[N] to_end = {}; for (int v = 0; v < N; v++) to_end[v] = -1;
    head = 0; tail = 1; to_end[endpoint] = 0; queue[0] = endpoint;
    while (head < tail) {
        int u = queue[head++];
        for (int v = 0; v < g.n; v++) if (g.adjacent[u][v] && to_end[v] < 0) { to_end[v] = to_end[u] + 1; queue[tail++] = v; }
    }
    int[N] p1 = {}, p2 = {}, p0 = {}; int p1_len = 1; p1[0] = g.center;
    while (p1[p1_len - 1] != endpoint && p1_len < N) {
        int u = p1[p1_len - 1], choice = -1;
        for (int v = 0; v < g.n; v++) if (g.adjacent[u][v] && to_end[v] == to_end[u] - 1 && (choice < 0 || v < choice)) choice = v;
        if (choice < 0) return -1;
        p1[p1_len++] = choice;
    }
    if (p1[p1_len - 1] != endpoint || p1_len - 1 != distance[endpoint]) return -1;
    for (int i = 0; i < p1_len; i++) p2[i] = g.permutation[p1[i]];
    int endpoint2 = p2[p1_len - 1]; if (endpoint2 == endpoint) return -1;
    for (int i = 1; i < p1_len; i++) for (int j = 1; j < p1_len; j++) if (p1[i] == p2[j]) return -1;
    for (int i = 1; i + 1 < p1_len; i++) for (int j = 0; j < g.b; j++) if (p1[i] == g.outer[j] || p2[i] == g.outer[j]) return -1;
    int start = -1; for (int i = 0; i < g.b; i++) if (g.outer[i] == endpoint) start = i;
    if (start < 0) return -1;
    int p0_len = g.b / g.k + 1;
    for (int i = 0; i < p0_len; i++) p0[i] = g.outer[(start + i) % g.b];
    if (p0[p0_len - 1] != endpoint2) return -1;
    int[3 * N] cycle = {}; int cycle_len = 0;
    for (int i = 0; i < p1_len; i++) cycle[cycle_len++] = p1[i];
    for (int i = 1; i < p0_len; i++) cycle[cycle_len++] = p0[i];
    for (int i = p1_len - 1; i > 0; i--) cycle[cycle_len++] = p2[i - 1];
    if (cycle[0] != g.center || cycle[cycle_len - 1] != g.center) return -1;
    bool[N] cycle_vertex = {}; bool[N][N] cut = {};
    for (int i = 0; i + 1 < cycle_len; i++) {
        int u = cycle[i], v = cycle[i + 1];
        if (!g.adjacent[u][v] || cycle_vertex[u]) return -1;
        cycle_vertex[u] = true; cut[u][v] = true; cut[v][u] = true;
    }
    int seed = g.dart_face[p0[1]][p0[0]];
    if (seed < 0 || seed == g.outer_id) return -1;
    bool[F][F] dual = {}; bool[F] inside = {};
    for (int e = 0; e < g.m; e++) {
        int u = g.edge_u[e], v = g.edge_v[e]; if (cut[u][v]) continue;
        int a = g.dart_face[u][v], b = g.dart_face[v][u]; dual[a][b] = true; dual[b][a] = true;
    }
    head = 0; tail = 1; queue[0] = seed; inside[seed] = true;
    while (head < tail) {
        int f = queue[head++];
        for (int other = 0; other < g.f; other++) if (dual[f][other] && !inside[other]) { inside[other] = true; queue[tail++] = other; }
    }
    if (inside[g.outer_id]) return -1;
    bool[N] vertices = cycle_vertex;
    for (int f = 0; f < g.f; f++) if (inside[f]) for (int i = 0; i < g.face_len[f]; i++) vertices[g.face[f][i]] = true;
    long vertex_mask = 0, edge_mask = 0;
    for (int v = 0; v < g.n; v++) if (vertices[v]) vertex_mask |= 1L << v;
    for (int e = 0; e < g.m; e++) if (vertices[g.edge_u[e]] && vertices[g.edge_v[e]]) edge_mask |= 1L << e;
    int count = 0; words[count++] = p1_len; for (int i = 0; i < p1_len; i++) words[count++] = p1[i];
    words[count++] = p1_len; for (int i = 0; i < p1_len; i++) words[count++] = p2[i];
    words[count++] = p0_len; for (int i = 0; i < p0_len; i++) words[count++] = p0[i];
    words[count++] = vertex_mask; words[count++] = edge_mask;
    return count;
}

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i++) output[offset + i] = (char)(bits >> (8 * i));
}

fn long symmetric_drawing_cyclic_wedge(long* input, usz input_length, char* output, usz output_capacity) {
    Graph g = {};
    if (!parse(input, input_length, &g)) return -1;
    long[29] words = {};
    int count = solve(&g, words);
    if (count < 0 || 8 * (usz)count > OUTPUT_MAX) return -1;
    usz bytes = 8 * (usz)count;
    if (output == null || output_capacity < bytes) return -2;
    char[OUTPUT_MAX] temporary = {};
    for (int i = 0; i < count; i++) write_i64_le(temporary, 8 * (usz)i, words[i]);
    for (usz i = 0; i < bytes; i++) output[i] = temporary[i];
    return (long)bytes;
}
