module minimum_cost_b_flow;

const int MAX_VERTICES = 8;
const int MAX_EDGES = 10;
const int MAX_ARCS = 2 * MAX_EDGES + 2 * MAX_VERTICES;
const int MAX_NODES = MAX_VERTICES + 2;
const usz MAX_INPUT_LENGTH = 61;
const int MAX_OUTPUT_WORDS = 2 + MAX_VERTICES + MAX_EDGES;

struct ResidualGraph {
    int[MAX_ARCS] from;
    int[MAX_ARCS] to;
    int[MAX_ARCS] reverse;
    long[MAX_ARCS] capacity;
    long[MAX_ARCS] cost;
    int arc_count;
    int original_arc_count;
}

fn int add_edge(ResidualGraph* graph, int from, int to, long capacity, long cost) {
    int forward = graph->arc_count;
    int backward = forward + 1;
    graph->arc_count += 2;
    graph->from[forward] = from; graph->to[forward] = to;
    graph->reverse[forward] = backward; graph->capacity[forward] = capacity; graph->cost[forward] = cost;
    graph->from[backward] = to; graph->to[backward] = from;
    graph->reverse[backward] = forward; graph->capacity[backward] = 0; graph->cost[backward] = -cost;
    return forward;
}

fn int feasible_flow(ResidualGraph* graph, int vertex_count, long required_flow) {
    int super_source = vertex_count, super_sink = vertex_count + 1;
    long sent = 0;
    while (sent < required_flow) {
        int[MAX_NODES] parent = {};
        int[MAX_NODES] seen = {};
        int[MAX_NODES] queue = {};
        for (int vertex = 0; vertex < MAX_NODES; vertex++) parent[vertex] = -1;
        int queue_head = 0, queue_length = 0;
        seen[super_source] = 1; queue[queue_length++] = super_source;
        while (queue_head < queue_length) {
            int vertex = queue[queue_head++];
            for (int edge = 0; edge < graph->arc_count; edge++) {
                int neighbor = graph->to[edge];
                if (graph->from[edge] == vertex && graph->capacity[edge] > 0 && seen[neighbor] == 0) {
                    seen[neighbor] = 1; parent[neighbor] = edge; queue[queue_length++] = neighbor;
                }
            }
        }
        if (seen[super_sink] == 0) return 0;
        long amount = required_flow - sent;
        for (int vertex = super_sink; vertex != super_source; vertex = graph->from[parent[vertex]])
            if (amount > graph->capacity[parent[vertex]]) amount = graph->capacity[parent[vertex]];
        for (int vertex = super_sink; vertex != super_source; vertex = graph->from[parent[vertex]]) {
            int edge = parent[vertex];
            graph->capacity[edge] -= amount;
            graph->capacity[graph->reverse[edge]] += amount;
        }
        sent += amount;
    }
    return 1;
}

fn int cancel_negative_cycles(ResidualGraph* graph, int vertex_count, int active_arcs) {
    if (vertex_count == 0) return 1;
    while (true) {
        long[MAX_VERTICES] distance = {};
        int[MAX_VERTICES] parent = {};
        for (int vertex = 0; vertex < MAX_VERTICES; vertex++) parent[vertex] = -1;
        int changed_vertex = -1;
        for (int pass = 0; pass < vertex_count; pass++) {
            changed_vertex = -1;
            for (int edge = 0; edge < active_arcs; edge++) {
                int from = graph->from[edge], to = graph->to[edge];
                if (graph->capacity[edge] > 0 && distance[to] > distance[from] + graph->cost[edge]) {
                    distance[to] = distance[from] + graph->cost[edge];
                    parent[to] = edge; changed_vertex = to;
                }
            }
            if (changed_vertex == -1) break;
        }
        if (changed_vertex == -1) return 1;
        int on_cycle = changed_vertex;
        for (int step = 0; step < vertex_count; step++) {
            int edge = parent[on_cycle];
            if (edge < 0) return 0;
            on_cycle = graph->from[edge];
        }
        long amount = 0x7fffffffffffffff;
        int vertex = on_cycle;
        do {
            int edge = parent[vertex];
            if (edge < 0) return 0;
            if (amount > graph->capacity[edge]) amount = graph->capacity[edge];
            vertex = graph->from[edge];
        } while (vertex != on_cycle);
        vertex = on_cycle;
        do {
            int edge = parent[vertex];
            graph->capacity[edge] -= amount;
            graph->capacity[graph->reverse[edge]] += amount;
            vertex = graph->from[edge];
        } while (vertex != on_cycle);
    }
}

fn int solve(int n, int m, long* input, long* words) {
    long[MAX_VERTICES] required = {};
    for (int vertex = 0; vertex < n; vertex++) required[vertex] = input[2 + vertex];
    int edge_offset = 2 + n;
    for (int edge = 0; edge < m; edge++) {
        int offset = edge_offset + 5 * edge;
        int from = (int)input[offset], to = (int)input[offset + 1];
        long lower = input[offset + 2];
        required[from] -= lower; required[to] += lower;
    }
    long required_sum = 0, required_flow = 0;
    for (int vertex = 0; vertex < n; vertex++) {
        required_sum += required[vertex];
        if (required[vertex] > 0) required_flow += required[vertex];
    }
    if (required_sum != 0) return 0;
    ResidualGraph graph = {};
    for (int edge = 0; edge < m; edge++) {
        int offset = edge_offset + 5 * edge;
        add_edge(&graph, (int)input[offset], (int)input[offset + 1],
            input[offset + 3] - input[offset + 2], input[offset + 4]);
    }
    graph.original_arc_count = graph.arc_count;
    for (int vertex = 0; vertex < n; vertex++) {
        if (required[vertex] > 0) add_edge(&graph, n, vertex, required[vertex], 0);
        else if (required[vertex] < 0) add_edge(&graph, vertex, n + 1, -required[vertex], 0);
    }
    if (feasible_flow(&graph, n, required_flow) == 0 ||
        cancel_negative_cycles(&graph, n, graph.original_arc_count) == 0) return 0;
    long[MAX_VERTICES] potential = {};
    for (int pass = 0; pass < n - 1; pass++) {
        int changed = 0;
        for (int edge = 0; edge < graph.original_arc_count; edge++) {
            int from = graph.from[edge], to = graph.to[edge];
            if (graph.capacity[edge] > 0 && potential[to] > potential[from] + graph.cost[edge]) {
                potential[to] = potential[from] + graph.cost[edge]; changed = 1;
            }
        }
        if (changed == 0) break;
    }
    words[0] = 1; words[1] = 0;
    for (int vertex = 0; vertex < n; vertex++) words[2 + vertex] = potential[vertex];
    for (int edge = 0; edge < m; edge++) {
        int offset = edge_offset + 5 * edge;
        long flow = input[offset + 3] - graph.capacity[2 * edge];
        words[2 + n + edge] = flow;
        words[1] += flow * input[offset + 4];
    }
    return 1;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long minimum_cost_b_flow(long* input, usz length, char* output, usz output_capacity)
    @export("minimum_cost_b_flow") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long raw_n = input[0], raw_m = input[1];
    if (raw_n < 0 || raw_n > MAX_VERTICES || raw_m < 0 || raw_m > MAX_EDGES) return -1;
    int n = (int)raw_n, m = (int)raw_m;
    if (length != (usz)(2 + n + 5 * m)) return -1;
    int edge_offset = 2 + n;
    for (int vertex = 0; vertex < n; vertex++) if (input[2 + vertex] < -5 || input[2 + vertex] > 5) return -1;
    for (int edge = 0; edge < m; edge++) {
        int offset = edge_offset + 5 * edge;
        long from = input[offset], to = input[offset + 1];
        long lower = input[offset + 2], upper = input[offset + 3], cost = input[offset + 4];
        if (from < 0 || from >= raw_n || to < 0 || to >= raw_n || lower < -3 || upper > 3 ||
            lower > upper || upper - lower > 2 || cost < -4 || cost > 4) return -1;
    }
    usz output_words = (usz)(2 + n + m), output_bytes = output_words * 8;
    if (output == null || output_capacity < output_bytes) return -2;
    long[MAX_OUTPUT_WORDS] words = {};
    if (solve(n, m, input, &words[0]) == 0) for (usz word = 0; word < output_words; word++) words[word] = 0;
    for (usz word = 0; word < output_words; word++) store_i64_le(output, word * 8, words[word]);
    return (long)output_bytes;
}
