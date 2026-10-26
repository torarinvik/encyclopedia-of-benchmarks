/* Clean-room bounded GAPBS Afforest profile; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 64, MAX_SAMPLES = 64, MAX_INPUT = 3 + MAX_SAMPLES + 2 * MAX_M };

static void link_components(int u, int v, int *component) {
    int p1 = component[u], p2 = component[v];
    while (p1 != p2) {
        const int high = p1 > p2 ? p1 : p2;
        const int low = p1 + (p2 - high);
        const int parent_high = component[high];
        if (parent_high == low) break;
        if (parent_high == high) {
            component[high] = low;
            break;
        }
        p1 = component[component[high]];
        p2 = component[low];
    }
}

static void compress_components(int n, int *component) {
    for (int vertex = 0; vertex < n; ++vertex)
        while (component[vertex] != component[component[vertex]])
            component[vertex] = component[component[vertex]];
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t gapbs_afforest_components(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1], sample_count64 = input[2];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        sample_count64 < 1 || sample_count64 > MAX_SAMPLES ||
        length != 3 + (size_t)sample_count64 + 2 * (size_t)m64) return -1;
    const int n = (int)n64, m = (int)m64, sample_count = (int)sample_count64;
    int samples[MAX_SAMPLES];
    for (int i = 0; i < sample_count; ++i) {
        const int64_t sample = input[3 + (size_t)i];
        if (sample < 0 || sample >= n64) return -1;
        samples[i] = (int)sample;
    }
    uint8_t adjacency[MAX_N][MAX_N] = {{0}};
    for (int edge = 0; edge < m; ++edge) {
        const size_t pos = 3 + (size_t)sample_count + 2 * (size_t)edge;
        const int64_t u = input[pos], v = input[pos + 1];
        if (u < 0 || v <= u || v >= n64 || adjacency[u][v]) return -1;
        adjacency[u][v] = adjacency[v][u] = 1;
    }
    const size_t output_bytes = 8 * (size_t)n;
    if (output == NULL || capacity < output_bytes) return -2;

    int neighbors[MAX_N][MAX_N] = {{0}}, degree[MAX_N] = {0};
    for (int u = 0; u < n; ++u)
        for (int v = 0; v < n; ++v)
            if (adjacency[u][v]) neighbors[u][degree[u]++] = v;
    int component[MAX_N];
    for (int vertex = 0; vertex < n; ++vertex) component[vertex] = vertex;

    for (int round = 0; round < 2; ++round) {
        for (int u = 0; u < n; ++u)
            if (degree[u] > round) link_components(u, neighbors[u][round], component);
        compress_components(n, component);
    }

    int sample_counts[MAX_N] = {0};
    for (int i = 0; i < sample_count; ++i) ++sample_counts[component[samples[i]]];
    int skip_label = 0;
    for (int label = 1; label < n; ++label)
        if (sample_counts[label] > sample_counts[skip_label]) skip_label = label;

    int skip_is_safe = 1;
    for (int u = 0; u < n && skip_is_safe; ++u) {
        if (component[u] != skip_label) continue;
        for (int offset = 2; offset < degree[u]; ++offset)
            if (component[neighbors[u][offset]] != skip_label) { skip_is_safe = 0; break; }
    }
    for (int u = 0; u < n; ++u) {
        if (skip_is_safe && component[u] == skip_label) continue;
        for (int offset = 2; offset < degree[u]; ++offset)
            link_components(u, neighbors[u][offset], component);
    }
    compress_components(n, component);
    for (int vertex = 0; vertex < n; ++vertex)
        store_i64_le(output, 8 * (size_t)vertex, component[vertex]);
    return (int64_t)output_bytes;
}
