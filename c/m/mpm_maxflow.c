#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_EDGES 24
#define MAX_INPUT_VALUES (4 + 3 * MAX_EDGES + 1)
#define MAX_FLOW INT64_C(2400)
#define FLOW_INFINITY (MAX_FLOW + 1)

static int64_t minimum(int64_t left, int64_t right) {
    return left < right ? left : right;
}

static int64_t push_forward(int vertex, int sink, int64_t amount, int n,
                            int64_t *residual, uint8_t *active,
                            int64_t *incoming, int64_t *outgoing) {
    if (vertex == sink) return amount;
    int64_t remaining = amount;
    for (int next = 0; next < n && remaining > 0; ++next) {
        const int edge = vertex * MAX_VERTICES + next;
        if (!active[edge] || residual[edge] == 0) continue;
        const int64_t pushed = push_forward(next, sink,
            minimum(remaining, residual[edge]), n, residual, active, incoming, outgoing);
        if (pushed == 0) continue;
        residual[edge] -= pushed;
        residual[next * MAX_VERTICES + vertex] += pushed;
        outgoing[vertex] -= pushed;
        incoming[next] -= pushed;
        remaining -= pushed;
        if (residual[edge] == 0) active[edge] = 0;
    }
    return amount - remaining;
}

static int64_t push_backward(int vertex, int source, int64_t amount, int n,
                             int64_t *residual, uint8_t *active,
                             int64_t *incoming, int64_t *outgoing) {
    if (vertex == source) return amount;
    int64_t remaining = amount;
    for (int previous = 0; previous < n && remaining > 0; ++previous) {
        const int edge = previous * MAX_VERTICES + vertex;
        if (!active[edge] || residual[edge] == 0) continue;
        const int64_t pushed = push_backward(previous, source,
            minimum(remaining, residual[edge]), n, residual, active, incoming, outgoing);
        if (pushed == 0) continue;
        residual[edge] -= pushed;
        residual[vertex * MAX_VERTICES + previous] += pushed;
        incoming[vertex] -= pushed;
        outgoing[previous] -= pushed;
        remaining -= pushed;
        if (residual[edge] == 0) active[edge] = 0;
    }
    return amount - remaining;
}

static void remove_vertex(int vertex, int n, int64_t *residual,
                          uint8_t *active, int64_t *incoming,
                          int64_t *outgoing, uint8_t *alive) {
    for (int other = 0; other < n; ++other) {
        const int incoming_edge = other * MAX_VERTICES + vertex;
        if (active[incoming_edge]) {
            const int64_t capacity = residual[incoming_edge];
            outgoing[other] -= capacity;
            incoming[vertex] -= capacity;
            active[incoming_edge] = 0;
        }
        const int outgoing_edge = vertex * MAX_VERTICES + other;
        if (active[outgoing_edge]) {
            const int64_t capacity = residual[outgoing_edge];
            outgoing[vertex] -= capacity;
            incoming[other] -= capacity;
            active[outgoing_edge] = 0;
        }
    }
    alive[vertex] = 0;
}

int64_t mpm_maxflow(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0], edge_count_value = input[1];
    const int64_t source_value = input[2], sink_value = input[3];
    if (n_value < 2 || n_value > MAX_VERTICES ||
        edge_count_value < 0 || edge_count_value > MAX_EDGES ||
        source_value < 1 || source_value > n_value ||
        sink_value < 1 || sink_value > n_value || source_value == sink_value)
        return -1;
    const int n = (int)n_value, edge_count = (int)edge_count_value;
    const int source = (int)source_value - 1, sink = (int)sink_value - 1;
    if (length != (size_t)(4 + 3 * edge_count)) return -1;

    int64_t residual[MAX_VERTICES * MAX_VERTICES] = {0};
    for (int edge = 0; edge < edge_count; ++edge) {
        const int64_t from_value = input[4 + 3 * edge];
        const int64_t to_value = input[5 + 3 * edge];
        const int64_t capacity = input[6 + 3 * edge];
        if (from_value < 1 || from_value > n_value || to_value < 1 ||
            to_value > n_value || from_value == to_value ||
            capacity < 0 || capacity > 100)
            return -1;
        residual[((int)from_value - 1) * MAX_VERTICES + (int)to_value - 1] += capacity;
    }

    int64_t total_flow = 0;
    for (;;) {
        int level[MAX_VERTICES];
        int queue[MAX_VERTICES];
        for (int vertex = 0; vertex < n; ++vertex) level[vertex] = -1;
        int head = 0, tail = 0;
        level[source] = 0;
        queue[tail++] = source;
        while (head < tail) {
            const int vertex = queue[head++];
            for (int next = 0; next < n; ++next) {
                if (residual[vertex * MAX_VERTICES + next] > 0 && level[next] < 0) {
                    level[next] = level[vertex] + 1;
                    queue[tail++] = next;
                }
            }
        }
        if (level[sink] < 0) break;

        int64_t incoming[MAX_VERTICES] = {0}, outgoing[MAX_VERTICES] = {0};
        uint8_t active[MAX_VERTICES * MAX_VERTICES] = {0};
        uint8_t alive[MAX_VERTICES] = {0};
        for (int vertex = 0; vertex < n; ++vertex)
            alive[vertex] = (uint8_t)(level[vertex] >= 0 && level[vertex] <= level[sink]);
        for (int from = 0; from < n; ++from) {
            for (int to = 0; to < n; ++to) {
                const int edge = from * MAX_VERTICES + to;
                if (level[from] >= 0 && level[from] < level[sink] &&
                    level[to] == level[from] + 1 && residual[edge] > 0) {
                    active[edge] = 1;
                    outgoing[from] += residual[edge];
                    incoming[to] += residual[edge];
                }
            }
        }
        incoming[source] = FLOW_INFINITY;
        outgoing[sink] = FLOW_INFINITY;

        for (;;) {
            int reference = -1;
            int64_t least_potential = FLOW_INFINITY + 1;
            for (int vertex = 0; vertex < n; ++vertex) {
                if (!alive[vertex]) continue;
                const int64_t potential = minimum(incoming[vertex], outgoing[vertex]);
                if (potential < least_potential) {
                    least_potential = potential;
                    reference = vertex;
                }
            }
            if (reference < 0) break;
            if (least_potential > 0) {
                total_flow += least_potential;
                (void)push_backward(reference, source, least_potential, n,
                    residual, active, incoming, outgoing);
                (void)push_forward(reference, sink, least_potential, n,
                    residual, active, incoming, outgoing);
            }
            remove_vertex(reference, n, residual, active, incoming, outgoing, alive);
        }
    }
    return total_flow;
}
