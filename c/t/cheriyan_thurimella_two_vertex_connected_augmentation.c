#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define CT_MAX_N 8
#define CT_MAX_M 28
#define CT_MAX_INPUT 59

static void ct_put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[at + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

static bool ct_biconnected(size_t n, size_t m, const size_t *u, const size_t *v,
                           const bool *active) {
    for (size_t removed = 0; removed < n; ++removed) {
        size_t start = removed == 0 ? 1 : 0;
        bool seen[CT_MAX_N] = {false};
        size_t queue[CT_MAX_N], head = 0, tail = 0;
        seen[start] = true;
        queue[tail++] = start;
        while (head < tail) {
            size_t current = queue[head++];
            for (size_t edge = 0; edge < m; ++edge) {
                if (!active[edge] || u[edge] == removed || v[edge] == removed) continue;
                size_t next = u[edge] == current ? v[edge] : v[edge] == current ? u[edge] : n;
                if (next < n && !seen[next]) {
                    seen[next] = true;
                    queue[tail++] = next;
                }
            }
        }
        for (size_t vertex = 0; vertex < n; ++vertex)
            if (vertex != removed && !seen[vertex]) return false;
    }
    return true;
}

int64_t cheriyan_thurimella_two_vertex_connected_augmentation(
        const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > CT_MAX_INPUT) return -1;
    int64_t n64 = input[0], m64 = input[1];
    if (n64 < 3 || n64 > CT_MAX_N || m64 < 3 || m64 > CT_MAX_M
            || length != 2 + 2 * (size_t)m64) return -1;
    size_t n = (size_t)n64, m = (size_t)m64;
    size_t u[CT_MAX_M], v[CT_MAX_M];
    for (size_t edge = 0; edge < m; ++edge) {
        int64_t a = input[2 + 2 * edge], b = input[3 + 2 * edge];
        if (a < 0 || a >= b || b >= n64) return -1;
        u[edge] = (size_t)a;
        v[edge] = (size_t)b;
        for (size_t prior = 0; prior < edge; ++prior)
            if (u[prior] == u[edge] && v[prior] == v[edge]) return -1;
    }
    bool active[CT_MAX_M];
    for (size_t edge = 0; edge < m; ++edge) active[edge] = true;
    if (!ct_biconnected(n, m, u, v, active)) return -1;
    size_t states = (size_t)1 << n;
    int best[1 << CT_MAX_N] = {0};
    int choice[1 << CT_MAX_N];
    for (size_t mask = 0; mask < states; ++mask) choice[mask] = -1;
    for (size_t mask = 1; mask < states; ++mask) {
        size_t first = 0;
        while (((mask >> first) & 1U) == 0) ++first;
        for (size_t edge = 0; edge < m; ++edge) {
            size_t other = n;
            if (u[edge] == first) other = v[edge];
            else if (v[edge] == first) other = u[edge];
            if (other == n || ((mask >> other) & 1U) == 0) continue;
            size_t rest = mask & ~((size_t)1 << first) & ~((size_t)1 << other);
            int candidate = 1 + best[rest];
            if (candidate > best[mask]) {
                best[mask] = candidate;
                choice[mask] = (int)edge;
            }
        }
        size_t rest = mask & ~((size_t)1 << first);
        if (best[rest] > best[mask]) { best[mask] = best[rest]; choice[mask] = -1; }
    }

    bool edge_cover[CT_MAX_M] = {false};
    bool covered[CT_MAX_N] = {false};
    size_t mask = states - 1;
    while (mask != 0) {
        size_t first = 0;
        while (((mask >> first) & 1U) == 0) ++first;
        int edge = choice[mask];
        if (edge < 0) {
            mask &= ~((size_t)1 << first);
            continue;
        }
        edge_cover[edge] = true;
        covered[u[edge]] = covered[v[edge]] = true;
        mask &= ~((size_t)1 << u[edge]) & ~((size_t)1 << v[edge]);
    }
    for (size_t vertex = 0; vertex < n; ++vertex) {
        if (covered[vertex]) continue;
        for (size_t edge = 0; edge < m; ++edge) {
            if (u[edge] == vertex || v[edge] == vertex) {
                edge_cover[edge] = true;
                covered[u[edge]] = covered[v[edge]] = true;
                break;
            }
        }
    }

    for (size_t edge = 0; edge < m; ++edge) {
        if (edge_cover[edge]) continue;
        active[edge] = false;
        if (!ct_biconnected(n, m, u, v, active)) active[edge] = true;
    }
    size_t count = 0;
    for (size_t edge = 0; edge < m; ++edge) if (active[edge]) ++count;
    size_t bytes = 8 * (1 + 2 * count);
    if (output == NULL || capacity < bytes) return -2;
    ct_put_i64(output, 0, (int64_t)count);
    size_t out_edge = 0;
    for (size_t edge = 0; edge < m; ++edge) {
        if (!active[edge]) continue;
        ct_put_i64(output, 8 * (1 + 2 * out_edge), (int64_t)u[edge]);
        ct_put_i64(output, 8 * (2 + 2 * out_edge), (int64_t)v[edge]);
        ++out_edge;
    }
    return (int64_t)bytes;
}
