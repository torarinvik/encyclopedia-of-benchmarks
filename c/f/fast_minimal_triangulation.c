#include <stddef.h>
#include <stdint.h>

#define FMT_N 8
#define FMT_M 28
#define FMT_INPUT 59
#define FMT_OUTPUT 456

static void fmt_put(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (int b = 0; b < 8; ++b) out[at + (size_t)b] = (uint8_t)(bits >> (8 * b));
}

static uint64_t fmt_recurse(uint16_t vertices, uint16_t graph[FMT_N]) {
    if (!vertices) return 0;
    int complete = 1;
    for (int u = 0; u < FMT_N; ++u) if ((vertices >> u) & 1u) {
        uint16_t others = (uint16_t)(vertices & ~(1u << u));
        if ((graph[u] & others) != others) { complete = 0; break; }
    }
    if (complete) return 0;

    int pivot = -1;
    for (int u = 0; u < FMT_N && pivot < 0; ++u) if ((vertices >> u) & 1u) {
        uint16_t others = (uint16_t)(vertices & ~(1u << u));
        if ((graph[u] & others) != others) pivot = u;
    }
    uint16_t a = (uint16_t)((1u << pivot) | (graph[pivot] & vertices));
    uint16_t unseen = (uint16_t)(vertices & ~a), components[FMT_N] = {0};
    uint16_t closures[FMT_N] = {0};
    int count = 0;
    while (unseen) {
        int seed = 0;
        while (((unseen >> seed) & 1u) == 0) ++seed;
        uint16_t comp = (uint16_t)(1u << seed);
        unseen = (uint16_t)(unseen & ~comp);
        uint16_t frontier = comp;
        while (frontier) {
            int u = 0;
            while (((frontier >> u) & 1u) == 0) ++u;
            frontier = (uint16_t)(frontier & ~(1u << u));
            uint16_t add = (uint16_t)(graph[u] & unseen);
            comp |= add; frontier |= add; unseen = (uint16_t)(unseen & ~add);
        }
        components[count++] = comp;
    }

    uint16_t next[FMT_N];
    for (int i = 0; i < FMT_N; ++i) next[i] = graph[i];
    uint64_t fill = 0;
    for (int c = 0; c < count; ++c) {
        uint16_t comp = components[c], boundary = 0;
        for (int u = 0; u < FMT_N; ++u) if ((comp >> u) & 1u)
            boundary |= (uint16_t)(graph[u] & vertices & ~comp);
        closures[c] = (uint16_t)(comp | boundary);
        for (int u = 0; u < FMT_N; ++u) if ((boundary >> u) & 1u)
            for (int v = u + 1; v < FMT_N; ++v) if ((boundary >> v) & 1u) {
                if (((next[u] >> v) & 1u) == 0) {
                    next[u] |= (uint16_t)(1u << v); next[v] |= (uint16_t)(1u << u);
                    fill |= UINT64_C(1) << (u * FMT_N + v);
                }
            }
    }
    fill |= fmt_recurse(a, next);
    for (int c = 0; c < count; ++c) fill |= fmt_recurse(closures[c], next);
    return fill;
}

int64_t fast_minimal_triangulation(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > FMT_INPUT) return -1;
    int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > FMT_N || m64 < 0 || m64 > FMT_M ||
        length != 2u + 2u * (size_t)m64) return -1;
    int n = (int)n64, m = (int)m64;
    uint16_t graph[FMT_N] = {0};
    int64_t prev_u = -1, prev_v = -1;
    uint64_t original = 0;
    for (int i = 0; i < m; ++i) {
        int64_t u64 = input[2 + 2 * i], v64 = input[3 + 2 * i];
        if (u64 < 0 || v64 <= u64 || v64 >= n64 ||
            u64 < prev_u || (u64 == prev_u && v64 <= prev_v)) return -1;
        int u = (int)u64, v = (int)v64;
        prev_u = u64; prev_v = v64;
        graph[u] |= (uint16_t)(1u << v); graph[v] |= (uint16_t)(1u << u);
        original |= UINT64_C(1) << (u * FMT_N + v);
    }
    uint16_t vertices = (uint16_t)((1u << n) - 1u);
    uint64_t added = fmt_recurse(vertices, graph) & ~original;
    int count = 0;
    for (int u = 0; u < n; ++u) for (int v = u + 1; v < n; ++v)
        if ((added >> (u * FMT_N + v)) & 1u) ++count;
    size_t bytes = 8u * (1u + 2u * (size_t)count);
    if (output == NULL || capacity < bytes) return -2;
    fmt_put(output, 0, count);
    int at = 1;
    for (int u = 0; u < n; ++u) for (int v = u + 1; v < n; ++v)
        if ((added >> (u * FMT_N + v)) & 1u) {
            fmt_put(output, 8u * (size_t)at++, u);
            fmt_put(output, 8u * (size_t)at++, v);
        }
    return (int64_t)bytes;
}
