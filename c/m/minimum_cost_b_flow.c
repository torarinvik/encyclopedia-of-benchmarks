#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_EDGES 10
#define MAX_ARCS (2 * MAX_EDGES + 2 * MAX_VERTICES)
#define MAX_NODES (MAX_VERTICES + 2)
#define MAX_INPUT_LENGTH (2 + MAX_VERTICES + 5 * MAX_EDGES + 1)
#define MAX_OUTPUT_WORDS (2 + MAX_VERTICES + MAX_EDGES)

typedef struct {
    int from[MAX_ARCS];
    int to[MAX_ARCS];
    int reverse[MAX_ARCS];
    int64_t capacity[MAX_ARCS];
    int64_t cost[MAX_ARCS];
    int arc_count;
    int original_arc_count;
} residual_graph;

static int add_edge(residual_graph *graph, int from, int to, int64_t capacity, int64_t cost) {
    const int forward = graph->arc_count++;
    const int reverse = graph->arc_count++;
    graph->from[forward] = from;
    graph->to[forward] = to;
    graph->reverse[forward] = reverse;
    graph->capacity[forward] = capacity;
    graph->cost[forward] = cost;
    graph->from[reverse] = to;
    graph->to[reverse] = from;
    graph->reverse[reverse] = forward;
    graph->capacity[reverse] = 0;
    graph->cost[reverse] = -cost;
    return forward;
}

static int feasible_flow(residual_graph *graph, int vertex_count, int64_t required_flow) {
    const int super_source = vertex_count;
    const int super_sink = vertex_count + 1;
    int64_t sent = 0;
    while (sent < required_flow) {
        int parent[MAX_NODES];
        int seen[MAX_NODES] = {0};
        int queue[MAX_NODES];
        int queue_head = 0, queue_length = 0;
        for (int vertex = 0; vertex < MAX_NODES; ++vertex) parent[vertex] = -1;
        seen[super_source] = 1;
        queue[queue_length++] = super_source;
        while (queue_head < queue_length) {
            const int vertex = queue[queue_head++];
            for (int edge = 0; edge < graph->arc_count; ++edge) {
                const int neighbor = graph->to[edge];
                if (graph->from[edge] == vertex && graph->capacity[edge] > 0 && !seen[neighbor]) {
                    seen[neighbor] = 1;
                    parent[neighbor] = edge;
                    queue[queue_length++] = neighbor;
                }
            }
        }
        if (!seen[super_sink]) return 0;
        int64_t amount = required_flow - sent;
        for (int vertex = super_sink; vertex != super_source; vertex = graph->from[parent[vertex]])
            if (amount > graph->capacity[parent[vertex]]) amount = graph->capacity[parent[vertex]];
        for (int vertex = super_sink; vertex != super_source; vertex = graph->from[parent[vertex]]) {
            const int edge = parent[vertex];
            graph->capacity[edge] -= amount;
            graph->capacity[graph->reverse[edge]] += amount;
        }
        sent += amount;
    }
    return 1;
}

static int cancel_negative_cycles(residual_graph *graph, int vertex_count, int active_arc_count) {
    if (vertex_count == 0) return 1;
    for (;;) {
        int64_t distance[MAX_VERTICES] = {0};
        int parent[MAX_VERTICES];
        for (int vertex = 0; vertex < MAX_VERTICES; ++vertex) parent[vertex] = -1;
        int changed_vertex = -1;
        for (int pass = 0; pass < vertex_count; ++pass) {
            changed_vertex = -1;
            for (int edge = 0; edge < active_arc_count; ++edge) {
                const int from = graph->from[edge], to = graph->to[edge];
                if (graph->capacity[edge] > 0 && distance[to] > distance[from] + graph->cost[edge]) {
                    distance[to] = distance[from] + graph->cost[edge];
                    parent[to] = edge;
                    changed_vertex = to;
                }
            }
            if (changed_vertex == -1) break;
        }
        if (changed_vertex == -1) return 1;
        int on_cycle = changed_vertex;
        for (int step = 0; step < vertex_count; ++step) {
            const int edge = parent[on_cycle];
            if (edge < 0) return 0;
            on_cycle = graph->from[edge];
        }
        int64_t amount = INT64_MAX;
        int vertex = on_cycle;
        do {
            const int edge = parent[vertex];
            if (edge < 0) return 0;
            if (amount > graph->capacity[edge]) amount = graph->capacity[edge];
            vertex = graph->from[edge];
        } while (vertex != on_cycle);
        vertex = on_cycle;
        do {
            const int edge = parent[vertex];
            graph->capacity[edge] -= amount;
            graph->capacity[graph->reverse[edge]] += amount;
            vertex = graph->from[edge];
        } while (vertex != on_cycle);
    }
}

static int solve(int vertex_count, int edge_count, const int64_t *balances,
                 const int64_t *input, int64_t *words) {
    int64_t required[MAX_VERTICES] = {0};
    for (int vertex = 0; vertex < vertex_count; ++vertex) required[vertex] = balances[vertex];
    const size_t edge_offset = 2 + (size_t)vertex_count;
    for (int edge = 0; edge < edge_count; ++edge) {
        const size_t offset = edge_offset + 5 * (size_t)edge;
        const int from = (int)input[offset], to = (int)input[offset + 1];
        const int64_t lower = input[offset + 2];
        required[from] -= lower;
        required[to] += lower;
    }
    int64_t required_total = 0, required_sum = 0;
    for (int vertex = 0; vertex < vertex_count; ++vertex) {
        required_sum += required[vertex];
        if (required[vertex] > 0) required_total += required[vertex];
    }
    if (required_sum != 0) return 0;

    residual_graph graph = {0};
    for (int edge = 0; edge < edge_count; ++edge) {
        const size_t offset = edge_offset + 5 * (size_t)edge;
        add_edge(&graph, (int)input[offset], (int)input[offset + 1],
                 input[offset + 3] - input[offset + 2], input[offset + 4]);
    }
    graph.original_arc_count = graph.arc_count;
    for (int vertex = 0; vertex < vertex_count; ++vertex) {
        if (required[vertex] > 0) add_edge(&graph, vertex_count, vertex, required[vertex], 0);
        else if (required[vertex] < 0) add_edge(&graph, vertex, vertex_count + 1, -required[vertex], 0);
    }
    if (!feasible_flow(&graph, vertex_count, required_total)) return 0;
    if (!cancel_negative_cycles(&graph, vertex_count, graph.original_arc_count)) return 0;

    int64_t potential[MAX_VERTICES] = {0};
    for (int pass = 0; pass < vertex_count - 1; ++pass) {
        int changed = 0;
        for (int edge = 0; edge < graph.original_arc_count; ++edge) {
            const int from = graph.from[edge], to = graph.to[edge];
            if (graph.capacity[edge] > 0 && potential[to] > potential[from] + graph.cost[edge]) {
                potential[to] = potential[from] + graph.cost[edge];
                changed = 1;
            }
        }
        if (!changed) break;
    }
    words[0] = 1;
    words[1] = 0;
    for (int edge = 0; edge < edge_count; ++edge) {
        const size_t offset = edge_offset + 5 * (size_t)edge;
        const int64_t flow = input[offset + 3] - graph.capacity[2 * edge];
        words[2 + vertex_count + edge] = flow;
        words[1] += flow * input[offset + 4];
    }
    for (int vertex = 0; vertex < vertex_count; ++vertex) words[2 + vertex] = potential[vertex];
    return 1;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)((bits >> (byte * 8)) & UINT64_C(0xff));
}

int64_t minimum_cost_b_flow(const int64_t *input, size_t length,
                            uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_vertices = input[0], raw_edges = input[1];
    if (raw_vertices < 0 || raw_vertices > MAX_VERTICES || raw_edges < 0 || raw_edges > MAX_EDGES)
        return -1;
    const int vertex_count = (int)raw_vertices, edge_count = (int)raw_edges;
    const size_t expected_length = 2 + (size_t)vertex_count + 5 * (size_t)edge_count;
    if (length != expected_length) return -1;
    const size_t edge_offset = 2 + (size_t)vertex_count;
    for (int vertex = 0; vertex < vertex_count; ++vertex)
        if (input[2 + vertex] < -5 || input[2 + vertex] > 5) return -1;
    for (int edge = 0; edge < edge_count; ++edge) {
        const size_t offset = edge_offset + 5 * (size_t)edge;
        const int64_t from = input[offset], to = input[offset + 1];
        const int64_t lower = input[offset + 2], upper = input[offset + 3], cost = input[offset + 4];
        if (from < 0 || from >= vertex_count || to < 0 || to >= vertex_count ||
            lower < -3 || upper > 3 || lower > upper || upper - lower > 2 || cost < -4 || cost > 4)
            return -1;
    }
    const size_t output_words = 2 + (size_t)vertex_count + (size_t)edge_count;
    const size_t output_bytes = output_words * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;

    int64_t words[MAX_OUTPUT_WORDS] = {0};
    const int feasible = solve(vertex_count, edge_count, input + 2, input, words);
    if (!feasible) {
        for (size_t word = 0; word < output_words; ++word) words[word] = 0;
    }
    for (size_t word = 0; word < output_words; ++word)
        store_i64_le(output, word * 8, words[word]);
    return (int64_t)output_bytes;
}
