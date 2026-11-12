module planar_face_count;

const usz MAX_N = 16;
const usz MAX_M = 42;
const usz MAX_INPUT = 118;
const long MAX_COORD = 100;

fn long orient(long* x, long* y, int a, int b, int c) {
    return (x[b] - x[a]) * (y[c] - y[a]) - (y[b] - y[a]) * (x[c] - x[a]);
}
fn bool between(long a, long b, long p) { return (a <= p && p <= b) || (b <= p && p <= a); }
fn bool on_segment(long* x, long* y, int a, int b, int p) {
    return between(x[a], x[b], x[p]) && between(y[a], y[b], y[p]);
}
fn bool segments_intersect(long* x, long* y, int a, int b, int c, int d) {
    long ab_c = orient(x, y, a, b, c), ab_d = orient(x, y, a, b, d);
    long cd_a = orient(x, y, c, d, a), cd_b = orient(x, y, c, d, b);
    if (((ab_c > 0 && ab_d < 0) || (ab_c < 0 && ab_d > 0)) &&
        ((cd_a > 0 && cd_b < 0) || (cd_a < 0 && cd_b > 0))) return true;
    return (ab_c == 0 && on_segment(x, y, a, b, c)) ||
        (ab_d == 0 && on_segment(x, y, a, b, d)) ||
        (cd_a == 0 && on_segment(x, y, c, d, a)) ||
        (cd_b == 0 && on_segment(x, y, c, d, b));
}
fn int angle_half(long dx, long dy) { return dy > 0 || (dy == 0 && dx >= 0) ? 0 : 1; }
fn bool angle_less(int a, int b, int origin, long* x, long* y) {
    long ax = x[a] - x[origin], ay = y[a] - y[origin];
    long bx = x[b] - x[origin], by = y[b] - y[origin];
    int ah = angle_half(ax, ay), bh = angle_half(bx, by);
    if (ah != bh) return ah < bh;
    return ax * by - ay * bx > 0;
}

fn long planar_face_count(long* input, usz length) @export("planar_face_count") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N || input[1] < 0 || input[1] > (long)MAX_M) return -1;
    int n = (int)input[0], m = (int)input[1];
    int edge_cap = n == 1 ? 0 : n == 2 ? 1 : 3 * n - 6;
    if (m > edge_cap || length != (usz)(2 + 2 * n + 2 * m)) return -1;
    long[MAX_N] x = {}, y = {};
    for (int v = 0; v < n; v++) {
        x[v] = input[2 + 2 * v]; y[v] = input[3 + 2 * v];
        if (x[v] < -MAX_COORD || x[v] > MAX_COORD || y[v] < -MAX_COORD || y[v] > MAX_COORD) return -1;
        for (int prior = 0; prior < v; prior++) if (x[v] == x[prior] && y[v] == y[prior]) return -1;
    }
    bool[MAX_N * MAX_N] adjacent = {};
    int[MAX_N * MAX_N] neighbors = {};
    int[MAX_N] degree = {};
    int[MAX_M] edge_u = {}, edge_v = {};
    usz offset = (usz)(2 + 2 * n);
    for (int e = 0; e < m; e++) {
        long u_value = input[offset + (usz)(2 * e)], v_value = input[offset + (usz)(2 * e + 1)];
        if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n || u_value == v_value) return -1;
        int u = (int)u_value, v = (int)v_value;
        if (adjacent[u * MAX_N + v]) return -1;
        adjacent[u * MAX_N + v] = true; adjacent[v * MAX_N + u] = true;
        neighbors[u * MAX_N + degree[u]++] = v; neighbors[v * MAX_N + degree[v]++] = u;
        edge_u[e] = u; edge_v[e] = v;
    }
    bool[MAX_N] reached = {};
    int[MAX_N] queue = {};
    int head = 0, tail = 0; reached[0] = true; queue[tail++] = 0;
    while (head < tail) {
        int u = queue[head++];
        for (int v = 0; v < n; v++) if (adjacent[u * MAX_N + v] && !reached[v]) {
            reached[v] = true; queue[tail++] = v;
        }
    }
    for (int v = 0; v < n; v++) if (!reached[v]) return -1;
    for (int i = 0; i < m; i++) for (int j = i + 1; j < m; j++) {
        int u = edge_u[i], v = edge_v[i], a = edge_u[j], b = edge_v[j];
        int common = -1;
        if (u == a || u == b) common = u;
        if (v == a || v == b) common = common < 0 ? v : common;
        if (common >= 0) {
            int p = u == common ? v : u, q = a == common ? b : a;
            long ax = x[p] - x[common], ay = y[p] - y[common];
            long bx = x[q] - x[common], by = y[q] - y[common];
            if (ax * by == ay * bx && ax * bx + ay * by > 0) return -1;
        } else if (segments_intersect(&x[0], &y[0], u, v, a, b)) return -1;
    }
    if (n == 1) return 1;
    for (int u = 0; u < n; u++) for (int i = 1; i < degree[u]; i++) {
        int key = neighbors[u * MAX_N + i], j = i;
        while (j > 0 && angle_less(key, neighbors[u * MAX_N + j - 1], u, &x[0], &y[0])) {
            neighbors[u * MAX_N + j] = neighbors[u * MAX_N + j - 1]; j--;
        }
        neighbors[u * MAX_N + j] = key;
    }
    bool[MAX_N * MAX_N] used = {};
    long faces = 0;
    for (int e = 0; e < m; e++) for (int direction = 0; direction < 2; direction++) {
        int u = direction == 0 ? edge_u[e] : edge_v[e];
        int v = direction == 0 ? edge_v[e] : edge_u[e];
        if (used[u * MAX_N + v]) continue;
        faces++;
        int steps = 0;
        while (!used[u * MAX_N + v]) {
            used[u * MAX_N + v] = true;
            int reverse = -1;
            for (int i = 0; i < degree[v]; i++) if (neighbors[v * MAX_N + i] == u) reverse = i;
            if (reverse < 0 || degree[v] == 0) return -1;
            int next = neighbors[v * MAX_N + (reverse + 1) % degree[v]];
            u = v; v = next;
            if (++steps > 2 * m) return -1;
        }
    }
    return faces;
}
