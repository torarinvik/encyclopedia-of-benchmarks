#include <stddef.h>
#include <stdint.h>

enum {
    MAX_VERTICES = 6,
    MAX_EDGES = 10,
    MAX_ADJACENCY_PER_VERTEX = 20,
    MAX_OUTPUT_VALUES = 13,
    MAX_OUTPUT_BYTES = 104,
    MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES
};

typedef struct {
    size_t vertex_count;
    size_t edge_count;
    size_t edge_left[MAX_EDGES];
    size_t edge_right[MAX_EDGES];
    size_t degree[MAX_VERTICES];
    size_t adjacent_vertex[MAX_VERTICES][MAX_ADJACENCY_PER_VERTEX];
    size_t adjacent_edge[MAX_VERTICES][MAX_ADJACENCY_PER_VERTEX];
    int64_t discovery[MAX_VERTICES];
    int64_t low[MAX_VERTICES];
    uint8_t is_bridge[MAX_EDGES];
    size_t clock;
    int64_t component[MAX_VERTICES];
    size_t block_vertices[MAX_VERTICES][MAX_VERTICES];
    size_t block_size[MAX_VERTICES];
    size_t block_count;
} graph_context;

static void find_bridges(graph_context *context, size_t vertex, size_t parent_edge) {
    context->discovery[vertex] = context->low[vertex] = (int64_t)context->clock++;
    for (size_t slot = 0; slot < context->degree[vertex]; ++slot) {
        const size_t neighbor = context->adjacent_vertex[vertex][slot];
        const size_t edge = context->adjacent_edge[vertex][slot];
        if (edge == parent_edge) continue;
        if (context->discovery[neighbor] < 0) {
            find_bridges(context, neighbor, edge);
            if (context->low[neighbor] < context->low[vertex])
                context->low[vertex] = context->low[neighbor];
            if (context->low[neighbor] > context->discovery[vertex]) context->is_bridge[edge] = 1;
        } else if (context->discovery[neighbor] < context->low[vertex]) {
            context->low[vertex] = context->discovery[neighbor];
        }
    }
}

static void assign_components(graph_context *context) {
    size_t queue[MAX_VERTICES];
    for (size_t root = 0; root < context->vertex_count; ++root) {
        if (context->component[root] >= 0) continue;
        const size_t block = context->block_count++;
        size_t head = 0, tail = 0;
        context->component[root] = (int64_t)block;
        queue[tail++] = root;
        while (head < tail) {
            const size_t vertex = queue[head++];
            for (size_t slot = 0; slot < context->degree[vertex]; ++slot) {
                const size_t neighbor = context->adjacent_vertex[vertex][slot];
                const size_t edge = context->adjacent_edge[vertex][slot];
                if (context->is_bridge[edge] || context->component[neighbor] >= 0) continue;
                context->component[neighbor] = (int64_t)block;
                queue[tail++] = neighbor;
            }
        }
        for (size_t vertex = 0; vertex < context->vertex_count; ++vertex)
            if (context->component[vertex] == (int64_t)block)
                context->block_vertices[block][context->block_size[block]++] = vertex;
    }
}

static int block_less(const graph_context *context, size_t left, size_t right) {
    const size_t common = context->block_size[left] < context->block_size[right]
        ? context->block_size[left] : context->block_size[right];
    for (size_t i = 0; i < common; ++i) {
        if (context->block_vertices[left][i] != context->block_vertices[right][i])
            return context->block_vertices[left][i] < context->block_vertices[right][i];
    }
    return context->block_size[left] < context->block_size[right];
}

static void store_u64_le(uint8_t *output, size_t offset, uint64_t value) {
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(value >> (8 * byte));
}

int64_t two_edge_connected_components(const int64_t *input, size_t length,
                                      uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES)
        return -1;
    const size_t vertex_count = (size_t)input[0];
    const size_t edge_count = (size_t)input[1];
    if (length != 2 + 2 * edge_count) return -1;

    graph_context context = {0};
    context.vertex_count = vertex_count;
    context.edge_count = edge_count;
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
        context.discovery[vertex] = -1;
        context.component[vertex] = -1;
    }
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t left = input[2 + 2 * edge];
        const int64_t right = input[3 + 2 * edge];
        if (left < 0 || left >= (int64_t)vertex_count || right < 0 || right >= (int64_t)vertex_count)
            return -1;
        const size_t u = (size_t)left, v = (size_t)right;
        context.edge_left[edge] = u;
        context.edge_right[edge] = v;
        const size_t u_slot = context.degree[u]++;
        const size_t v_slot = context.degree[v]++;
        context.adjacent_vertex[u][u_slot] = v;
        context.adjacent_edge[u][u_slot] = edge;
        context.adjacent_vertex[v][v_slot] = u;
        context.adjacent_edge[v][v_slot] = edge;
    }
    for (size_t root = 0; root < vertex_count; ++root)
        if (context.discovery[root] < 0) find_bridges(&context, root, MAX_EDGES);
    assign_components(&context);

    size_t order[MAX_VERTICES];
    for (size_t i = 0; i < context.block_count; ++i) {
        size_t position = i;
        order[i] = i;
        while (position > 0 && block_less(&context, order[position], order[position - 1])) {
            const size_t temporary = order[position];
            order[position] = order[position - 1];
            order[position - 1] = temporary;
            --position;
        }
    }
    uint64_t packed[MAX_OUTPUT_VALUES];
    size_t packed_count = 0;
    packed[packed_count++] = (uint64_t)context.block_count;
    for (size_t i = 0; i < context.block_count; ++i) {
        const size_t block = order[i];
        packed[packed_count++] = (uint64_t)context.block_size[block];
        for (size_t j = 0; j < context.block_size[block]; ++j)
            packed[packed_count++] = (uint64_t)context.block_vertices[block][j];
    }
    const size_t bytes = 8 * packed_count;
    if (output == NULL || output_capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES];
    for (size_t i = 0; i < packed_count; ++i) store_u64_le(staged, 8 * i, packed[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
