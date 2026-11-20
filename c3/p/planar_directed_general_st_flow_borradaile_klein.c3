module planar_directed_general_st_flow_borradaile_klein;

const int N = 6, M = 10, DARTS = 20, FACES = 10, MAX_INPUT = 61, MAX_AUG = 25;
const long INF = 0x3fffffffffffffff;

struct Graph {
    int n, m, source, sink;
    int[M] u, v, cap;
    int[N] degree;
    int[N][N] rotation;
    int[N][M] local_pos;
    int[DARTS] left_face, right_face;
    int faces, infinity_face, root_anchor;
}

fn int dart_head(Graph* g, int dart) {
    int edge = dart / 2;
    return (dart & 1) != 0 ? g.u[edge] : g.v[edge];
}

fn int next_left_dart(Graph* g, int dart) {
    int vertex = dart_head(g, dart);
    int edge = dart / 2;
    int degree = g.degree[vertex];
    int position = g.local_pos[vertex][edge];
    if (degree <= 0 || position < 0) return -1;
    int prior = g.rotation[vertex][(position + degree - 1) % degree];
    return 2 * prior + (g.v[prior] == vertex ? 1 : 0);
}

fn bool decode(long* a, usz length, Graph* g) {
    if (a == null || length < 4 || length > MAX_INPUT) return false;
    long n0 = a[0], m0 = a[1], s0 = a[2], t0 = a[3];
    if (n0 < 2 || n0 > N || m0 < 1 || m0 > M || s0 < 0 || s0 >= n0 ||
        t0 < 0 || t0 >= n0 || s0 == t0 || length < (usz)(4 + 3 * m0)) return false;
    g.n = n0.int(); g.m = m0.int(); g.source = s0.int(); g.sink = t0.int();
    bool[N][N] pairs = zeroed;
    usz at = 4;
    for (int e = 0; e < g.m; e++) {
        long u0 = a[at++], v0 = a[at++], c0 = a[at++];
        if (u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0 || c0 < 1 || c0 > 5) return false;
        int u = u0.int(), v = v0.int();
        if (pairs[u][v] || pairs[v][u]) return false;
        pairs[u][v] = true; pairs[v][u] = true;
        g.u[e] = u; g.v[e] = v; g.cap[e] = c0.int();
    }
    int[N][M] occurrences = zeroed;
    bool[N][M] used = zeroed;
    for (int x = 0; x < g.n; x++) for (int e = 0; e < g.m; e++) g.local_pos[x][e] = -1;
    for (int x = 0; x < g.n; x++) {
        if (at >= length) return false;
        long d0 = a[at++];
        if (d0 < 1 || d0 > g.n - 1 || at + d0.usz() > length) return false;
        int d = d0.int(); g.degree[x] = d;
        for (int j = 0; j < d; j++) {
            long e0 = a[at++];
            if (e0 < 0 || e0 >= g.m) return false;
            int edge = e0.int();
            if (used[x][edge]) return false;
            used[x][edge] = true; g.rotation[x][j] = edge; g.local_pos[x][edge] = j;
            if (g.u[edge] == x) occurrences[x][edge]++;
            else if (g.v[edge] == x) occurrences[x][edge]++;
            else return false;
        }
    }
    if (at != length) return false;
    for (int e = 0; e < g.m; e++) {
        if (occurrences[g.u[e]][e] != 1 || occurrences[g.v[e]][e] != 1) return false;
    }
    bool[N] connected = zeroed; int[N] queue = zeroed; int head = 0, tail = 0;
    connected[g.source] = true; queue[tail++] = g.source;
    while (head < tail) {
        int x = queue[head++];
        for (int e = 0; e < g.m; e++) {
            int y = g.u[e] == x ? g.v[e] : (g.v[e] == x ? g.u[e] : -1);
            if (y >= 0 && !connected[y]) { connected[y] = true; queue[tail++] = y; }
        }
    }
    for (int x = 0; x < g.n; x++) if (!connected[x]) return false;
    for (int d = 0; d < 2 * g.m; d++) g.left_face[d] = -1;
    g.faces = 0;
    for (int start = 0; start < 2 * g.m; start++) {
        if (g.left_face[start] >= 0) continue;
        int dart = start;
        while (g.left_face[dart] < 0) {
            g.left_face[dart] = g.faces;
            dart = next_left_dart(g, dart);
            if (dart < 0) return false;
        }
        if (dart != start) return false;
        g.faces++;
    }
    if (g.faces != g.m - g.n + 2) return false;
    for (int d = 0; d < 2 * g.m; d++) g.right_face[d] = g.left_face[d ^ 1];
    g.root_anchor = g.rotation[g.sink][0];
    int anchor_dart = 2 * g.root_anchor + (g.v[g.root_anchor] == g.sink ? 1 : 0);
    g.infinity_face = g.right_face[anchor_dart];
    return true;
}

fn void right_first(Graph* g, int vertex, int anchor, bool root,
                    int[N][N]* residual, bool[N]* seen,
                    int[N]* parent, int[N]* parent_edge) {
    int degree = g.degree[vertex], position = g.local_pos[vertex][anchor];
    int first = root ? 0 : 1;
    for (int step = first; step < first + degree; step++) {
        int edge = g.rotation[vertex][(position + step) % degree];
        int neighbor = g.u[edge] == vertex ? g.v[edge] : g.u[edge];
        if (!seen[neighbor] && residual[neighbor][vertex] > 0) {
            seen[neighbor] = true; parent[neighbor] = vertex; parent_edge[neighbor] = edge;
            right_first(g, neighbor, edge, false, residual, seen, parent, parent_edge);
        }
    }
}

fn long solve(Graph* g) {
    long[FACES][FACES] dual = zeroed;
    long[FACES] distance = zeroed; bool[FACES] settled = zeroed;
    for (int f = 0; f < g.faces; f++) {
        distance[f] = INF;
        for (int h = 0; h < g.faces; h++) dual[f][h] = INF;
    }
    for (int d = 0; d < 2 * g.m; d++) {
        int from = g.right_face[d], to = g.left_face[d];
        long weight = (d & 1) != 0 ? 0 : g.cap[d / 2];
        if (weight < dual[from][to]) dual[from][to] = weight;
    }
    distance[g.infinity_face] = 0;
    for (int count = 0; count < g.faces; count++) {
        int current = -1;
        for (int f = 0; f < g.faces; f++)
            if (!settled[f] && (current < 0 || distance[f] < distance[current])) current = f;
        if (current < 0 || distance[current] == INF) break;
        settled[current] = true;
        for (int next = 0; next < g.faces; next++) {
            if (dual[current][next] == INF) continue;
            long candidate = distance[current] + dual[current][next];
            if (candidate < distance[next]) distance[next] = candidate;
        }
    }
    int[N][N] residual = zeroed;
    for (int e = 0; e < g.m; e++) {
        long eta = distance[g.left_face[2 * e]] - distance[g.right_face[2 * e]];
        if (eta < 0 || eta > g.cap[e]) return -1;
        residual[g.u[e]][g.v[e]] += g.cap[e] - eta.int();
        residual[g.v[e]][g.u[e]] += eta.int();
    }
    long total = 0;
    for (int augmentation = 0; augmentation <= MAX_AUG; augmentation++) {
        bool[N] seen = zeroed; int[N] parent = zeroed, parent_edge = zeroed;
        for (int x = 0; x < g.n; x++) parent[x] = parent_edge[x] = -1;
        seen[g.sink] = true;
        right_first(g, g.sink, g.root_anchor, true, &residual, &seen, &parent, &parent_edge);
        if (!seen[g.source]) return total;
        if (augmentation == MAX_AUG) return -1;
        int delta = 0x7fffffff;
        for (int x = g.source; x != g.sink; x = parent[x])
            if (residual[x][parent[x]] < delta) delta = residual[x][parent[x]];
        for (int x = g.source; x != g.sink; x = parent[x]) {
            int y = parent[x]; residual[x][y] -= delta; residual[y][x] += delta;
        }
        total += delta;
    }
    return -1;
}

fn void put_i64(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long planar_directed_general_st_flow_borradaile_klein(
    long* input, usz length, char* output, usz capacity) @export("planar_directed_general_st_flow_borradaile_klein") {
    if (input == null) return -1;
    Graph graph = zeroed;
    if (!decode(input, length, &graph)) return -1;
    long value = solve(&graph);
    if (value < 0) return -1;
    if (output == null || capacity < 8) return -2;
    put_i64(output, value);
    return 8;
}
