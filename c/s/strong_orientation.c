#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 64
#define MAX_EDGES 128
#define MAX_ARCS (2 * MAX_EDGES)
#define MAX_INPUT_LENGTH (2 + 2 * MAX_EDGES + 1)

typedef struct {
    int head[MAX_VERTICES];
    int tail[MAX_VERTICES];
    int to[MAX_ARCS];
    int next[MAX_ARCS];
    int arc_edge[MAX_ARCS];
    int edge_u[MAX_EDGES];
    int edge_used[MAX_EDGES];
    int direction[MAX_EDGES];
    int discovery[MAX_VERTICES];
    int low[MAX_VERTICES];
    int timer;
    int bridges;
} orientation_graph;

static void append_arc(orientation_graph *graph, int from, int to, int edge, int *arc_count) {
    const int arc = (*arc_count)++;
    graph->to[arc] = to;
    graph->arc_edge[arc] = edge;
    graph->next[arc] = -1;
    if (graph->head[from] == -1) graph->head[from] = arc;
    else graph->next[graph->tail[from]] = arc;
    graph->tail[from] = arc;
}

static void visit(orientation_graph *graph, int vertex) {
    graph->discovery[vertex] = graph->low[vertex] = graph->timer++;
    for (int arc = graph->head[vertex]; arc != -1; arc = graph->next[arc]) {
        const int edge = graph->arc_edge[arc];
        if (graph->edge_used[edge]) continue;
        graph->edge_used[edge] = 1;
        graph->direction[edge] = vertex == graph->edge_u[edge] ? 1 : -1;
        const int neighbor = graph->to[arc];
        if (graph->discovery[neighbor] == -1) {
            visit(graph, neighbor);
            if (graph->low[neighbor] < graph->low[vertex]) graph->low[vertex] = graph->low[neighbor];
            if (graph->low[neighbor] > graph->discovery[vertex]) ++graph->bridges;
        } else if (graph->discovery[neighbor] < graph->low[vertex]) {
            graph->low[vertex] = graph->discovery[neighbor];
        }
    }
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)((bits >> (byte * 8)) & UINT64_C(0xff));
}

int64_t strong_orientation(const int64_t *input, size_t length,
                           uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_vertices = input[0], raw_edges = input[1];
    if (raw_vertices < 1 || raw_vertices > MAX_VERTICES || raw_edges < 0 || raw_edges > MAX_EDGES)
        return -1;
    const size_t vertex_count = (size_t)raw_vertices;
    const size_t edge_count = (size_t)raw_edges;
    if (length != 2 + 2 * edge_count) return -1;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t left = input[2 + 2 * edge], right = input[3 + 2 * edge];
        if (left < 0 || right < 0 || left >= (int64_t)vertex_count || right >= (int64_t)vertex_count)
            return -1;
    }
    const size_t output_bytes = 8 * (edge_count + 1);
    if (output == NULL || output_capacity < output_bytes) return -2;

    orientation_graph graph = {0};
    for (size_t vertex = 0; vertex < MAX_VERTICES; ++vertex) {
        graph.head[vertex] = -1;
        graph.tail[vertex] = -1;
        graph.discovery[vertex] = -1;
    }
    int arc_count = 0;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int left = (int)input[2 + 2 * edge];
        const int right = (int)input[3 + 2 * edge];
        graph.edge_u[edge] = left;
        append_arc(&graph, left, right, (int)edge, &arc_count);
        append_arc(&graph, right, left, (int)edge, &arc_count);
    }
    int components = 0;
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
        if (graph.discovery[vertex] == -1) {
            ++components;
            visit(&graph, (int)vertex);
        }
    }
    store_i64_le(output, 0, components + graph.bridges);
    for (size_t edge = 0; edge < edge_count; ++edge)
        store_i64_le(output, 8 * (edge + 1), graph.direction[edge]);
    return (int64_t)output_bytes;
}
