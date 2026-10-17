#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

#define MAX_VERTICES 16
#define MAX_EDGES 64
#define MAX_INPUT_WORDS 194
#define MAX_OUTPUT_WORDS (1 + 3 * (MAX_VERTICES - 1))
#define MAX_OUTPUT_BYTES (4 * MAX_OUTPUT_WORDS)

typedef struct { int32_t u, v, weight; } Edge;

static int32_t find_root(int32_t *parent, int32_t node) {
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

static void put_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t minimum_spanning_tree_kruskal2(const int32_t *input, size_t length,
                                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_WORDS) return -1;
    const int32_t vertex_count = input[0], edge_count = input[1];
    if (vertex_count < 1 || vertex_count > MAX_VERTICES || edge_count < 0 || edge_count > MAX_EDGES ||
        length != 2 + 3 * (size_t)edge_count) return -1;

    Edge input_edges[MAX_EDGES];
    bool seen[MAX_VERTICES][MAX_VERTICES] = {{false}};
    size_t pos = 2;
    for (int32_t i = 0; i < edge_count; ++i) {
        const int32_t u = input[pos++], v = input[pos++], weight = input[pos++];
        if (u < 0 || v <= u || v >= vertex_count || seen[u][v]) return -1;
        seen[u][v] = true;
        input_edges[i] = (Edge){u, v, weight};
    }

    int32_t parent[MAX_VERTICES], rank[MAX_VERTICES] = {0};
    for (int32_t i = 0; i < vertex_count; ++i) parent[i] = i;
    for (int32_t i = 0; i < edge_count; ++i) {
        const int32_t root_u = find_root(parent, input_edges[i].u);
        const int32_t root_v = find_root(parent, input_edges[i].v);
        if (root_u != root_v) parent[root_u] = root_v;
    }
    for (int32_t i = 1; i < vertex_count; ++i)
        if (find_root(parent, i) != find_root(parent, 0)) return -1;

    Edge ordered[MAX_EDGES];
    size_t ordered_count = 0;
    for (int32_t u = 0; u < vertex_count; ++u)
        for (int32_t i = 0; i < edge_count; ++i)
            if (input_edges[i].u == u) ordered[ordered_count++] = input_edges[i];
    for (size_t i = 1; i < ordered_count; ++i) {
        const Edge key = ordered[i];
        size_t j = i;
        while (j > 0 && ordered[j - 1].weight > key.weight) {
            ordered[j] = ordered[j - 1];
            --j;
        }
        ordered[j] = key;
    }

    for (int32_t i = 0; i < vertex_count; ++i) parent[i] = i, rank[i] = 0;
    int32_t words[MAX_OUTPUT_WORDS] = {0};
    size_t word_count = 1, accepted = 0;
    for (size_t i = 0; i < ordered_count && accepted < (size_t)(vertex_count - 1); ++i) {
        const int32_t root_u = find_root(parent, ordered[i].u);
        const int32_t root_v = find_root(parent, ordered[i].v);
        if (root_u == root_v) continue;
        if (rank[root_u] < rank[root_v]) parent[root_u] = root_v;
        else if (rank[root_u] > rank[root_v]) parent[root_v] = root_u;
        else { parent[root_u] = root_v; ++rank[root_v]; }
        words[word_count++] = ordered[i].u;
        words[word_count++] = ordered[i].v;
        words[word_count++] = ordered[i].weight;
        ++accepted;
    }
    if (accepted != (size_t)(vertex_count - 1)) return -1;
    words[0] = (int32_t)accepted;
    const size_t bytes = word_count * 4;
    if (bytes > MAX_OUTPUT_BYTES || output == NULL || capacity < bytes) return -2;
    uint8_t buffer[MAX_OUTPUT_BYTES];
    for (size_t i = 0; i < word_count; ++i) put_i32_le(buffer, i * 4, words[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = buffer[i];
    return (int64_t)bytes;
}
