#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 16
#define MAX_EDGES 64
#define MAX_PARSEABLE_INPUT_LENGTH (2 + 3 * MAX_EDGES + 1)
#define MAX_OUTPUT_WORDS (1 + 2 * (MAX_VERTICES - 1))
#define MAX_OUTPUT_BYTES (4 * MAX_OUTPUT_WORDS)
#define SOURCE_HEAP_SENTINEL INT64_MAX

static void top_to_bottom(int64_t *heap, int32_t *positions, int32_t *node_position,
                          size_t size, size_t start) {
    size_t root = start;
    while (root * 2 + 1 < size) {
        const size_t left = root * 2 + 1;
        const size_t right = left + 1;
        const size_t child = right >= size || heap[left] < heap[right] ? left : right;
        if (heap[child] >= heap[root]) break;

        const int64_t heap_value = heap[root];
        heap[root] = heap[child];
        heap[child] = heap_value;
        const int32_t vertex = positions[root];
        positions[root] = positions[child];
        positions[child] = vertex;
        node_position[positions[root]] = (int32_t)root;
        node_position[positions[child]] = (int32_t)child;
        root = child;
    }
}

static void decrease_key(int64_t value, size_t index, int64_t *heap,
                         int32_t *positions, int32_t *node_position) {
    const int32_t vertex = positions[index];
    while (index != 0) {
        const size_t parent = (index - 1) / 2;
        if (value < heap[parent]) {
            heap[index] = heap[parent];
            positions[index] = positions[parent];
            node_position[positions[parent]] = (int32_t)index;
        } else {
            heap[index] = value;
            positions[index] = vertex;
            node_position[vertex] = (int32_t)index;
            return;
        }
        index = parent;
    }
    heap[0] = value;
    positions[0] = vertex;
    node_position[vertex] = 0;
}

static void put_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t minimum_spanning_tree_prims(const int32_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int32_t raw_vertices = input[0];
    const int32_t raw_edges = input[1];
    if (raw_vertices < 1 || raw_vertices > MAX_VERTICES || raw_edges < 0 || raw_edges > MAX_EDGES)
        return -1;
    const size_t vertex_count = (size_t)raw_vertices;
    const size_t edge_count = (size_t)raw_edges;
    if (length != 2 + 3 * edge_count) return -1;

    int32_t neighbors[MAX_VERTICES][MAX_VERTICES] = {{0}};
    int32_t weights[MAX_VERTICES][MAX_VERTICES] = {{0}};
    int32_t degree[MAX_VERTICES] = {0};
    bool seen[MAX_VERTICES][MAX_VERTICES] = {{false}};
    for (size_t index = 0; index < edge_count; ++index) {
        const size_t offset = 2 + 3 * index;
        const int32_t u = input[offset];
        const int32_t v = input[offset + 1];
        const int32_t weight = input[offset + 2];
        if (u < 0 || v <= u || v >= raw_vertices || seen[u][v]) return -1;
        seen[u][v] = true;
        const int32_t u_degree = degree[u]++;
        neighbors[u][u_degree] = v;
        weights[u][u_degree] = weight;
        const int32_t v_degree = degree[v]++;
        neighbors[v][v_degree] = u;
        weights[v][v_degree] = weight;
    }

    if (vertex_count > 1) {
        bool visited[MAX_VERTICES] = {false};
        int32_t stack[MAX_VERTICES];
        size_t stack_size = 1, reached = 0;
        stack[0] = 0;
        visited[0] = true;
        while (stack_size > 0) {
            const int32_t vertex = stack[--stack_size];
            ++reached;
            for (int32_t i = 0; i < degree[vertex]; ++i) {
                const int32_t neighbor = neighbors[vertex][i];
                if (!visited[neighbor]) {
                    visited[neighbor] = true;
                    stack[stack_size++] = neighbor;
                }
            }
        }
        if (reached != vertex_count) return -1;
    }

    bool visited[MAX_VERTICES] = {false};
    int32_t parent[MAX_VERTICES];
    int64_t heap[MAX_VERTICES];
    int32_t positions[MAX_VERTICES], node_position[MAX_VERTICES];
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
        parent[vertex] = -1;
        heap[vertex] = SOURCE_HEAP_SENTINEL;
        positions[vertex] = (int32_t)vertex;
        node_position[vertex] = (int32_t)vertex;
    }
    visited[0] = true;
    for (int32_t i = 0; i < degree[0]; ++i) {
        const int32_t neighbor = neighbors[0][i];
        parent[neighbor] = 0;
        heap[neighbor] = weights[0][i];
    }
    for (size_t start = vertex_count / 2; start > 0; --start)
        top_to_bottom(heap, positions, node_position, vertex_count, start - 1);

    int32_t words[MAX_OUTPUT_WORDS] = {0};
    size_t word_count = 1;
    size_t tree_edge_count = 0;
    for (size_t step = 1; step < vertex_count; ++step) {
        const int32_t vertex = positions[0];
        heap[0] = SOURCE_HEAP_SENTINEL;
        top_to_bottom(heap, positions, node_position, vertex_count, 0);
        if (!visited[vertex]) {
            words[word_count++] = parent[vertex];
            words[word_count++] = vertex;
            ++tree_edge_count;
            visited[vertex] = true;
            for (int32_t i = 0; i < degree[vertex]; ++i) {
                const int32_t neighbor = neighbors[vertex][i];
                const int32_t weight = weights[vertex][i];
                if (!visited[neighbor]) {
                    const size_t heap_index = (size_t)node_position[neighbor];
                    if ((int64_t)weight < heap[heap_index]) {
                        heap[heap_index] = weight;
                        decrease_key(weight, heap_index, heap, positions, node_position);
                        parent[neighbor] = vertex;
                    }
                }
            }
        }
    }
    if (tree_edge_count != vertex_count - 1) return -1;
    words[0] = (int32_t)tree_edge_count;
    const size_t word_count_total = word_count;
    const size_t byte_count = word_count_total * 4;
    if (byte_count > MAX_OUTPUT_BYTES || output == NULL || capacity < byte_count) return -2;
    uint8_t buffer[MAX_OUTPUT_BYTES];
    for (size_t index = 0; index < word_count_total; ++index)
        put_i32_le(buffer, index * 4, words[index]);
    for (size_t index = 0; index < byte_count; ++index) output[index] = buffer[index];
    return (int64_t)byte_count;
}
