#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#define KV_MAX_N 8
#define KV_MAX_M 28
#define KV_MAX_INPUT 59

static void kv_put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) { out[at + i] = (uint8_t)(bits & 255U); bits >>= 8; }
}

static bool kv_connected_without_vertex(size_t n, size_t m, const size_t *u,
                                        const size_t *v, size_t removed) {
    bool seen[KV_MAX_N] = {false};
    size_t start = removed == 0 ? 1 : 0;
    size_t queue[KV_MAX_N], head = 0, tail = 1;
    queue[0] = start; seen[start] = true;
    while (head < tail) {
        size_t at = queue[head++];
        for (size_t e = 0; e < m; ++e) {
            if (u[e] == removed || v[e] == removed) continue;
            size_t next = KV_MAX_N;
            if (u[e] == at) next = v[e]; else if (v[e] == at) next = u[e];
            if (next < n && !seen[next]) { seen[next] = true; queue[tail++] = next; }
        }
    }
    for (size_t i = 0; i < n; ++i) if (i != removed && !seen[i]) return false;
    return true;
}

static bool kv_earlier(size_t a, size_t b, const size_t *disc) { return disc[a] < disc[b]; }

int64_t two_vertex_connected_spanning_subgraph_khuller_vishkin_dfs(
        const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > KV_MAX_INPUT) return -1;
    int64_t n64 = input[0], m64 = input[1];
    if (n64 < 3 || n64 > KV_MAX_N || m64 < 3 || m64 > KV_MAX_M || length != 2 + 2 * (size_t)m64) return -1;
    size_t n = (size_t)n64, m = (size_t)m64;
    size_t u[KV_MAX_M], v[KV_MAX_M];
    for (size_t e = 0; e < m; ++e) {
        int64_t a = input[2 + 2 * e], b = input[3 + 2 * e];
        if (a < 0 || a >= b || b >= n64) return -1;
        u[e] = (size_t)a; v[e] = (size_t)b;
        for (size_t j = 0; j < e; ++j) if (u[j] == u[e] && v[j] == v[e]) return -1;
    }
    for (size_t removed = 0; removed < n; ++removed)
        if (!kv_connected_without_vertex(n, m, u, v, removed)) return -1;

    size_t state[KV_MAX_N] = {0}, disc[KV_MAX_N] = {0};
    size_t low[KV_MAX_N] = {0}, low_h[KV_MAX_N] = {0}, savior[KV_MAX_N] = {0};
    size_t parent_edge[KV_MAX_N] = {0};
    bool selected[KV_MAX_M] = {false};
    size_t stack_v[KV_MAX_N], stack_parent[KV_MAX_N], stack_cursor[KV_MAX_N];
    size_t tick = 1, top = 1;
    state[0] = 1; disc[0] = 0; low[0] = low_h[0] = savior[0] = 0;
    stack_v[0] = 0; stack_parent[0] = KV_MAX_N; stack_cursor[0] = 0;

    while (top > 0) {
        size_t frame = top - 1, x = stack_v[frame], parent = stack_parent[frame];
        if (stack_cursor[frame] < m) {
            size_t e = stack_cursor[frame]++;
            size_t w = KV_MAX_N;
            if (u[e] == x) w = v[e]; else if (v[e] == x) w = u[e];
            if (w == KV_MAX_N) continue;
            if (state[w] == 0) {
                selected[e] = true;
                parent_edge[w] = e;
                state[w] = 1; disc[w] = tick++; low[w] = low_h[w] = savior[w] = w;
                stack_v[top] = w; stack_parent[top] = x; stack_cursor[top] = 0; ++top;
            } else if (state[w] == 1 && w != parent && kv_earlier(w, low[x], disc)) {
                low[x] = w; savior[x] = x;
            }
            continue;
        }
        state[x] = 2;
        if (parent < n && low_h[x] == x) {
            size_t a = savior[x], b = low[x];
            size_t lo = a < b ? a : b, hi = a < b ? b : a;
            for (size_t e = 0; e < m; ++e) if (u[e] == lo && v[e] == hi) { selected[e] = true; break; }
            low_h[x] = low[x];
        }
        if (parent < n && low_h[x] == parent) {
            size_t a = savior[x], b = low[x];
            size_t lo = a < b ? a : b, hi = a < b ? b : a;
            for (size_t e = 0; e < m; ++e) if (u[e] == lo && v[e] == hi) { selected[e] = true; break; }
            low_h[x] = low[x];
            if (savior[x] == x) selected[parent_edge[x]] = false;
        }
        --top;
        if (parent < n) {
            if (kv_earlier(low[x], low[parent], disc)) { low[parent] = low[x]; savior[parent] = savior[x]; }
            if (kv_earlier(low_h[x], low_h[parent], disc)) low_h[parent] = low_h[x];
        }
    }

    size_t count = 0;
    for (size_t e = 0; e < m; ++e) if (selected[e]) ++count;
    size_t bytes = 8 * (1 + 2 * count);
    if (output == NULL || capacity < bytes) return -2;
    kv_put_i64(output, 0, (int64_t)count);
    size_t at = 8;
    for (size_t a = 0; a < n; ++a) for (size_t b = a + 1; b < n; ++b)
        for (size_t e = 0; e < m; ++e) if (selected[e] && u[e] == a && v[e] == b) {
            kv_put_i64(output, at, (int64_t)a); kv_put_i64(output, at + 8, (int64_t)b); at += 16;
        }
    return (int64_t)bytes;
}
