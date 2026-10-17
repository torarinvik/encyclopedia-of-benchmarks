#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 64
#define MAX_OUTPUT_BYTES 1016

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int make_code(const int64_t *input, size_t n, int64_t *code) {
    uint8_t adjacency[MAX_VERTICES][MAX_VERTICES] = {{0}};
    size_t degree[MAX_VERTICES] = {0};
    for (size_t edge = 0; edge + 1 < n; ++edge) {
        const int64_t raw_u = input[2 + edge * 2];
        const int64_t raw_v = input[3 + edge * 2];
        if (raw_u < 0 || raw_v < 0 || raw_u >= (int64_t)n || raw_v >= (int64_t)n || raw_u == raw_v) return -1;
        const size_t u = (size_t)raw_u, v = (size_t)raw_v;
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = adjacency[v][u] = 1;
        ++degree[u]; ++degree[v];
    }

    uint8_t visited[MAX_VERTICES] = {0};
    size_t queue[MAX_VERTICES], head = 0, tail = 0;
    visited[0] = 1; queue[tail++] = 0;
    while (head < tail) {
        const size_t u = queue[head++];
        for (size_t v = 0; v < n; ++v) {
            if (adjacency[u][v] && !visited[v]) { visited[v] = 1; queue[tail++] = v; }
        }
    }
    if (tail != n) return -1;

    uint8_t active[MAX_VERTICES] = {0};
    for (size_t v = 0; v < n; ++v) active[v] = 1;
    for (size_t step = 0; step + 2 < n; ++step) {
        int64_t leaf = -1;
        for (size_t v = n; v > 0; --v) {
            const size_t candidate = v - 1;
            if (active[candidate] && degree[candidate] == 1) { leaf = (int64_t)candidate; break; }
        }
        if (leaf < 0) return -1;
        size_t neighbor = n;
        for (size_t v = 0; v < n; ++v) {
            if (active[v] && adjacency[(size_t)leaf][v]) { neighbor = v; break; }
        }
        if (neighbor == n) return -1;
        code[step] = (int64_t)neighbor;
        active[(size_t)leaf] = 0;
        adjacency[(size_t)leaf][neighbor] = adjacency[neighbor][(size_t)leaf] = 0;
        --degree[neighbor];
    }
    return (int)(n > 2 ? n - 2 : 0);
}

static void add_edge(int64_t edges[MAX_VERTICES - 1][2], size_t index, size_t u, size_t v) {
    if (u < v) { edges[index][0] = (int64_t)u; edges[index][1] = (int64_t)v; }
    else { edges[index][0] = (int64_t)v; edges[index][1] = (int64_t)u; }
}

static int make_decoded_edges(const int64_t *input, size_t n, int64_t edges[MAX_VERTICES - 1][2]) {
    size_t remaining[MAX_VERTICES] = {0};
    for (size_t i = 0; i + 2 < n; ++i) {
        const int64_t raw = input[2 + i];
        if (raw < 0 || raw >= (int64_t)n) return -1;
        ++remaining[(size_t)raw];
    }
    uint8_t active[MAX_VERTICES] = {0};
    for (size_t v = 0; v < n; ++v) active[v] = 1;
    size_t out = 0;
    for (size_t i = 0; i + 2 < n; ++i) {
        size_t leaf = n;
        for (size_t v = n; v > 0; --v) {
            const size_t candidate = v - 1;
            if (active[candidate] && remaining[candidate] == 0) { leaf = candidate; break; }
        }
        if (leaf == n) return -1;
        const size_t vertex = (size_t)input[2 + i];
        add_edge(edges, out++, leaf, vertex);
        active[leaf] = 0;
        --remaining[vertex];
    }
    size_t first = n;
    for (size_t v = n; v > 0; --v) if (active[v - 1]) { first = v - 1; break; }
    if (first == n) return -1;
    active[first] = 0;
    size_t second = n;
    for (size_t v = n; v > 0; --v) if (active[v - 1]) { second = v - 1; break; }
    if (second == n) return -1;
    add_edge(edges, out++, first, second);
    for (size_t i = 1; i < out; ++i) {
        int64_t u = edges[i][0], v = edges[i][1];
        size_t j = i;
        while (j > 0 && (edges[j - 1][0] > u || (edges[j - 1][0] == u && edges[j - 1][1] > v))) {
            edges[j][0] = edges[j - 1][0]; edges[j][1] = edges[j - 1][1]; --j;
        }
        edges[j][0] = u; edges[j][1] = v;
    }
    return (int)out;
}

int64_t prufer_code(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 129) return -1;
    const int64_t mode = input[0], raw_n = input[1];
    if (raw_n < 1 || raw_n > MAX_VERTICES || (mode != 0 && mode != 1)) return -1;
    const size_t n = (size_t)raw_n;
    if (mode == 0) {
        if (length != 2 * n) return -1;
        int64_t code[MAX_VERTICES] = {0};
        const int code_length = make_code(input, n, code);
        if (code_length < 0) return -1;
        const size_t needed = (size_t)code_length * 8;
        if (needed == 0) return 0;
        if (output == NULL || capacity < needed) return -2;
        for (int i = 0; i < code_length; ++i) write_i64_le(output, (size_t)i * 8, code[i]);
        return (int64_t)needed;
    }
    if (n < 2 || length != n) return -1;
    int64_t edges[MAX_VERTICES - 1][2] = {{0}};
    const int edge_count = make_decoded_edges(input, n, edges);
    if (edge_count < 0) return -1;
    const size_t needed = 8 + (size_t)edge_count * 16;
    if (needed > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || capacity < needed) return -2;
    write_i64_le(output, 0, edge_count);
    for (int i = 0; i < edge_count; ++i) {
        write_i64_le(output, 8 + (size_t)i * 16, edges[i][0]);
        write_i64_le(output, 16 + (size_t)i * 16, edges[i][1]);
    }
    return (int64_t)needed;
}
