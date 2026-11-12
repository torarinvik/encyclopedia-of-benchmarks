#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 42, MAX_INPUT = 118, MAX_COORD = 100 };

static int64_t orient(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                      int64_t cx, int64_t cy) {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

static bool between(int64_t a, int64_t b, int64_t p) {
    return (a <= p && p <= b) || (b <= p && p <= a);
}

static bool on_segment(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                       int64_t px, int64_t py) {
    return between(ax, bx, px) && between(ay, by, py);
}

static bool segments_intersect(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                               int64_t cx, int64_t cy, int64_t dx, int64_t dy) {
    const int64_t ab_c = orient(ax, ay, bx, by, cx, cy);
    const int64_t ab_d = orient(ax, ay, bx, by, dx, dy);
    const int64_t cd_a = orient(cx, cy, dx, dy, ax, ay);
    const int64_t cd_b = orient(cx, cy, dx, dy, bx, by);
    if (((ab_c > 0 && ab_d < 0) || (ab_c < 0 && ab_d > 0)) &&
        ((cd_a > 0 && cd_b < 0) || (cd_a < 0 && cd_b > 0))) return true;
    return (ab_c == 0 && on_segment(ax, ay, bx, by, cx, cy)) ||
           (ab_d == 0 && on_segment(ax, ay, bx, by, dx, dy)) ||
           (cd_a == 0 && on_segment(cx, cy, dx, dy, ax, ay)) ||
           (cd_b == 0 && on_segment(cx, cy, dx, dy, bx, by));
}

static int angle_half(int64_t dx, int64_t dy) {
    return dy > 0 || (dy == 0 && dx >= 0) ? 0 : 1;
}

static bool neighbor_less(int a, int b, int origin,
                          const int64_t x[MAX_N], const int64_t y[MAX_N]) {
    const int64_t ax = x[a] - x[origin], ay = y[a] - y[origin];
    const int64_t bx = x[b] - x[origin], by = y[b] - y[origin];
    const int ah = angle_half(ax, ay), bh = angle_half(bx, by);
    if (ah != bh) return ah < bh;
    return ax * by - ay * bx > 0;
}

int64_t planar_face_count(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_M) return -1;
    const int n = (int)input[0], m = (int)input[1];
    const int edge_cap = n == 1 ? 0 : n == 2 ? 1 : 3 * n - 6;
    if (m > edge_cap || length != (size_t)(2 + 2 * n + 2 * m)) return -1;

    int64_t x[MAX_N], y[MAX_N];
    for (int v = 0; v < n; ++v) {
        x[v] = input[2 + 2 * v];
        y[v] = input[3 + 2 * v];
        if (x[v] < -MAX_COORD || x[v] > MAX_COORD || y[v] < -MAX_COORD || y[v] > MAX_COORD) return -1;
        for (int prior = 0; prior < v; ++prior) if (x[v] == x[prior] && y[v] == y[prior]) return -1;
    }

    bool adjacent[MAX_N][MAX_N] = {{false}};
    int neighbors[MAX_N][MAX_N] = {{0}}, degree[MAX_N] = {0};
    int edge_u[MAX_M], edge_v[MAX_M];
    const size_t edge_offset = (size_t)(2 + 2 * n);
    for (int e = 0; e < m; ++e) {
        const int64_t u_value = input[edge_offset + (size_t)(2 * e)];
        const int64_t v_value = input[edge_offset + (size_t)(2 * e + 1)];
        if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n || u_value == v_value) return -1;
        const int u = (int)u_value, v = (int)v_value;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = true;
        neighbors[u][degree[u]++] = v;
        neighbors[v][degree[v]++] = u;
        edge_u[e] = u;
        edge_v[e] = v;
    }

    bool reached[MAX_N] = {false};
    int queue[MAX_N], head = 0, tail = 0;
    reached[0] = true;
    queue[tail++] = 0;
    while (head < tail) {
        const int u = queue[head++];
        for (int v = 0; v < n; ++v) if (adjacent[u][v] && !reached[v]) {
            reached[v] = true;
            queue[tail++] = v;
        }
    }
    for (int v = 0; v < n; ++v) if (!reached[v]) return -1;

    for (int i = 0; i < m; ++i) for (int j = i + 1; j < m; ++j) {
        const int u = edge_u[i], v = edge_v[i], a = edge_u[j], b = edge_v[j];
        int common = -1;
        if (u == a || u == b) common = u;
        if (v == a || v == b) common = common < 0 ? v : common;
        if (common >= 0) {
            const int other1 = u == common ? v : u;
            const int other2 = a == common ? b : a;
            const int64_t ax = x[other1] - x[common], ay = y[other1] - y[common];
            const int64_t bx = x[other2] - x[common], by = y[other2] - y[common];
            if (ax * by == ay * bx && ax * bx + ay * by > 0) return -1;
        } else if (segments_intersect(x[u], y[u], x[v], y[v], x[a], y[a], x[b], y[b])) {
            return -1;
        }
    }
    if (n == 1) return 1;

    for (int u = 0; u < n; ++u) for (int i = 1; i < degree[u]; ++i) {
        const int key = neighbors[u][i];
        int j = i;
        while (j > 0 && neighbor_less(key, neighbors[u][j - 1], u, x, y)) {
            neighbors[u][j] = neighbors[u][j - 1];
            --j;
        }
        neighbors[u][j] = key;
    }

    bool used[MAX_N][MAX_N] = {{false}};
    int faces = 0;
    for (int e = 0; e < m; ++e) for (int direction = 0; direction < 2; ++direction) {
        int u = direction == 0 ? edge_u[e] : edge_v[e];
        int v = direction == 0 ? edge_v[e] : edge_u[e];
        if (used[u][v]) continue;
        ++faces;
        int steps = 0;
        while (!used[u][v]) {
            used[u][v] = true;
            int reverse_index = -1;
            for (int i = 0; i < degree[v]; ++i) if (neighbors[v][i] == u) reverse_index = i;
            if (reverse_index < 0 || degree[v] == 0) return -1;
            const int next = neighbors[v][(reverse_index + 1) % degree[v]];
            u = v;
            v = next;
            if (++steps > 2 * m) return -1;
        }
    }
    return faces;
}
