#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define MAX_VERTICES 64
#define MAX_EDGES 4096
#define MAX_INPUT_LENGTH (2 + 3 * MAX_EDGES)

typedef struct {
    int64_t u;
    int64_t v;
    int64_t weight;
    size_t input_order;
} Edge;

static int compare_edges(const void *left, const void *right) {
    const Edge *a = (const Edge *)left;
    const Edge *b = (const Edge *)right;
    if (a->weight < b->weight) return -1;
    if (a->weight > b->weight) return 1;
    if (a->input_order < b->input_order) return -1;
    if (a->input_order > b->input_order) return 1;
    return 0;
}

static size_t find_root(size_t *parent, size_t node) {
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t minimum_spanning_tree_kruskal(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_vertices = input[0];
    const int64_t raw_edges = input[1];
    if (raw_vertices < 0 || raw_vertices > MAX_VERTICES ||
        raw_edges < 0 || raw_edges > MAX_EDGES) return -1;
    const size_t vertex_count = (size_t)raw_vertices;
    const size_t edge_count = (size_t)raw_edges;
    if (length != 2 + 3 * edge_count) return -1;

    Edge edges[MAX_EDGES];
    for (size_t index = 0; index < edge_count; ++index) {
        const size_t offset = 2 + 3 * index;
        const int64_t u = input[offset];
        const int64_t v = input[offset + 1];
        if (u < 0 || u >= raw_vertices || v < 0 || v >= raw_vertices) return -1;
        edges[index] = (Edge){u, v, input[offset + 2], index};
    }
    qsort(edges, edge_count, sizeof(Edge), compare_edges);

    size_t parent[MAX_VERTICES];
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) parent[vertex] = vertex;
    Edge accepted[MAX_VERTICES];
    size_t accepted_count = 0;
    for (size_t index = 0; index < edge_count; ++index) {
        const size_t left_root = find_root(parent, (size_t)edges[index].u);
        const size_t right_root = find_root(parent, (size_t)edges[index].v);
        if (left_root != right_root) {
            accepted[accepted_count++] = edges[index];
            parent[left_root] = right_root;
        }
    }

    const size_t byte_count = accepted_count * 24;
    if (output == NULL || capacity < byte_count) return -2;
    for (size_t index = 0; index < accepted_count; ++index) {
        const size_t offset = index * 24;
        put_i64_le(output, offset, accepted[index].u);
        put_i64_le(output, offset + 8, accepted[index].v);
        put_i64_le(output, offset + 16, accepted[index].weight);
    }
    return (int64_t)byte_count;
}
