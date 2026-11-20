#include <stddef.h>
#include <stdint.h>

int64_t undirected_eulerian_trail_hierholzer(const int64_t *input, size_t length,
                                              uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 67 || input[0] < 1 || input[0] > 16 ||
        input[1] < 0 || input[1] > 32) return -1;
    size_t n = (size_t)input[0], m = (size_t)input[1];
    if (length != 2 + 2 * m) return -1;
    size_t endpoints[32][2], degree[16] = {0};
    size_t incident[16][64], cursor[16] = {0};
    for (size_t e = 0; e < m; ++e) {
        int64_t u = input[2 + 2 * e], v = input[3 + 2 * e];
        if (u < 0 || v < 0 || u >= (int64_t)n || v >= (int64_t)n) return -1;
        endpoints[e][0] = (size_t)u; endpoints[e][1] = (size_t)v;
        incident[u][degree[u]++] = e; incident[v][degree[v]++] = e;
    }
    size_t odd_count = 0, start = 0;
    for (size_t v = 0; v < n; ++v)
        if (degree[v] & 1) { if (odd_count == 0) start = v; ++odd_count; }
    if (odd_count != 0 && odd_count != 2) return 0;
    if (odd_count == 0 && m != 0)
        while (degree[start] == 0) ++start;
    uint8_t used[32] = {0};
    size_t stack[33], reverse[33], top = 1, count = 0;
    stack[0] = start;
    while (top != 0) {
        size_t v = stack[top - 1];
        while (cursor[v] < degree[v] && used[incident[v][cursor[v]]]) ++cursor[v];
        if (cursor[v] == degree[v]) reverse[count++] = stack[--top];
        else {
            size_t edge = incident[v][cursor[v]++];
            used[edge] = 1;
            stack[top++] = endpoints[edge][0] == v ? endpoints[edge][1] : endpoints[edge][0];
        }
    }
    if (count != m + 1) return 0;
    size_t bytes = count * 8;
    if (!output || capacity < bytes) return -2;
    for (size_t i = 0; i < count; ++i) {
        uint64_t value = reverse[count - 1 - i];
        for (size_t b = 0; b < 8; ++b) output[8 * i + b] = (uint8_t)(value >> (8 * b));
    }
    return (int64_t)bytes;
}
