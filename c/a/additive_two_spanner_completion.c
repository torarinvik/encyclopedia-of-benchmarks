#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define A2_MAX_N 8
#define A2_MAX_M 28
#define A2_MAX_INPUT 59
#define A2_INF 9

static void a2_put(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[at + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

static void a2_distances(size_t n, size_t m, const size_t *u, const size_t *v,
                         const bool *selected, bool only_selected,
                         size_t distance[A2_MAX_N][A2_MAX_N]) {
    for (size_t a = 0; a < n; ++a)
        for (size_t b = 0; b < n; ++b)
            distance[a][b] = a == b ? 0 : A2_INF;
    for (size_t edge = 0; edge < m; ++edge) {
        if (only_selected && !selected[edge]) continue;
        distance[u[edge]][v[edge]] = 1;
        distance[v[edge]][u[edge]] = 1;
    }
    for (size_t via = 0; via < n; ++via)
        for (size_t left = 0; left < n; ++left)
            for (size_t right = 0; right < n; ++right) {
                size_t candidate = distance[left][via] + distance[via][right];
                if (candidate < distance[left][right]) distance[left][right] = candidate;
            }
}

int64_t additive_two_spanner_completion(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > A2_MAX_INPUT) return -1;
    int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > A2_MAX_N || m64 < 0 || m64 > A2_MAX_M
            || length != 2 + 2 * (size_t)m64) return -1;
    size_t n = (size_t)n64, m = (size_t)m64;
    size_t u[A2_MAX_M], v[A2_MAX_M];
    for (size_t edge = 0; edge < m; ++edge) {
        int64_t a = input[2 + 2 * edge], b = input[3 + 2 * edge];
        if (a < 0 || a >= b || b >= n64) return -1;
        u[edge] = (size_t)a;
        v[edge] = (size_t)b;
        for (size_t prior = 0; prior < edge; ++prior)
            if (u[prior] == u[edge] && v[prior] == v[edge]) return -1;
    }

    size_t original[A2_MAX_N][A2_MAX_N];
    a2_distances(n, m, u, v, NULL, false, original);
    bool selected[A2_MAX_M] = {false};
    for (size_t round = 0; round <= m; ++round) {
        size_t current[A2_MAX_N][A2_MAX_N];
        a2_distances(n, m, u, v, selected, true, current);
        size_t source = n, target = n;
        for (size_t a = 0; a < n && source == n; ++a)
            for (size_t b = a + 1; b < n; ++b)
                if (original[a][b] < A2_INF && current[a][b] > original[a][b] + 2) {
                    source = a; target = b; break;
                }
        if (source == n) break;
        if (round == m) return -1;
        size_t vertex = source;
        while (vertex != target) {
            size_t next = n;
            for (size_t neighbor = 0; neighbor < n; ++neighbor)
                if (neighbor != vertex && original[neighbor][target] + 1 == original[vertex][target]) {
                    for (size_t edge = 0; edge < m; ++edge)
                        if ((u[edge] == vertex && v[edge] == neighbor)
                                || (v[edge] == vertex && u[edge] == neighbor)) {
                            next = neighbor; selected[edge] = true; break;
                        }
                    if (next != n) break;
                }
            if (next == n) return -1;
            vertex = next;
        }
    }

    size_t count = 0;
    for (size_t edge = 0; edge < m; ++edge) if (selected[edge]) ++count;
    size_t bytes = 8 * (1 + 2 * count);
    if (output == NULL || capacity < bytes) return -2;
    a2_put(output, 0, (int64_t)count);
    size_t slot = 0;
    for (size_t edge = 0; edge < m; ++edge) if (selected[edge]) {
        a2_put(output, 8 * (1 + 2 * slot), (int64_t)u[edge]);
        a2_put(output, 8 * (2 + 2 * slot), (int64_t)v[edge]);
        ++slot;
    }
    return (int64_t)bytes;
}
