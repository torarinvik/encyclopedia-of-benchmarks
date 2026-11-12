module mpm_maxflow;

const int MAX_VERTICES = 8;
const int MAX_EDGES = 24;
const usz MAX_INPUT_VALUES = 4 + 3 * MAX_EDGES + 1;
const long FLOW_INFINITY = 2401;

fn long minimum(long left, long right) {
    return left < right ? left : right;
}

fn long push_forward(int vertex, int sink, long amount, int n,
    long* residual, bool* active, long* incoming, long* outgoing) {
    if (vertex == sink) return amount;
    long remaining = amount;
    for (int next = 0; next < n && remaining > 0; next += 1) {
        int edge = vertex * MAX_VERTICES + next;
        if (!active[edge] || residual[edge] == 0) continue;
        long pushed = push_forward(next, sink,
            minimum(remaining, residual[edge]), n, residual, active, incoming, outgoing);
        if (pushed == 0) continue;
        residual[edge] -= pushed;
        residual[next * MAX_VERTICES + vertex] += pushed;
        outgoing[vertex] -= pushed;
        incoming[next] -= pushed;
        remaining -= pushed;
        if (residual[edge] == 0) active[edge] = false;
    }
    return amount - remaining;
}

fn long push_backward(int vertex, int source, long amount, int n,
    long* residual, bool* active, long* incoming, long* outgoing) {
    if (vertex == source) return amount;
    long remaining = amount;
    for (int previous = 0; previous < n && remaining > 0; previous += 1) {
        int edge = previous * MAX_VERTICES + vertex;
        if (!active[edge] || residual[edge] == 0) continue;
        long pushed = push_backward(previous, source,
            minimum(remaining, residual[edge]), n, residual, active, incoming, outgoing);
        if (pushed == 0) continue;
        residual[edge] -= pushed;
        residual[vertex * MAX_VERTICES + previous] += pushed;
        incoming[vertex] -= pushed;
        outgoing[previous] -= pushed;
        remaining -= pushed;
        if (residual[edge] == 0) active[edge] = false;
    }
    return amount - remaining;
}

fn void remove_vertex(int vertex, int n, long* residual, bool* active,
    long* incoming, long* outgoing, bool* alive) {
    for (int other = 0; other < n; other += 1) {
        int incoming_edge = other * MAX_VERTICES + vertex;
        if (active[incoming_edge]) {
            long capacity = residual[incoming_edge];
            outgoing[other] -= capacity;
            incoming[vertex] -= capacity;
            active[incoming_edge] = false;
        }
        int outgoing_edge = vertex * MAX_VERTICES + other;
        if (active[outgoing_edge]) {
            long capacity = residual[outgoing_edge];
            outgoing[vertex] -= capacity;
            incoming[other] -= capacity;
            active[outgoing_edge] = false;
        }
    }
    alive[vertex] = false;
}

fn long mpm_maxflow(long* input, usz length) @export("mpm_maxflow") {
    if (input == null || length < 4 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0], edge_count_value = input[1];
    long source_value = input[2], sink_value = input[3];
    if (n_value < 2 || n_value > MAX_VERTICES || edge_count_value < 0 ||
        edge_count_value > MAX_EDGES || source_value < 1 || source_value > n_value ||
        sink_value < 1 || sink_value > n_value || source_value == sink_value) return -1;
    int n = (int)n_value, edge_count = (int)edge_count_value;
    int source = (int)source_value - 1, sink = (int)sink_value - 1;
    if (length != (usz)(4 + 3 * edge_count)) return -1;

    long[MAX_VERTICES * MAX_VERTICES] residual = zeroed;
    for (int edge = 0; edge < edge_count; edge += 1) {
        long from_value = input[4 + 3 * edge];
        long to_value = input[5 + 3 * edge];
        long capacity = input[6 + 3 * edge];
        if (from_value < 1 || from_value > n_value || to_value < 1 || to_value > n_value ||
            from_value == to_value || capacity < 0 || capacity > 100) return -1;
        residual[((int)from_value - 1) * MAX_VERTICES + (int)to_value - 1] += capacity;
    }

    long total_flow = 0;
    while (true) {
        int[MAX_VERTICES] level;
        int[MAX_VERTICES] queue;
        for (int vertex = 0; vertex < n; vertex += 1) level[vertex] = -1;
        int head = 0, tail = 0;
        level[source] = 0;
        queue[tail++] = source;
        while (head < tail) {
            int vertex = queue[head++];
            for (int next = 0; next < n; next += 1) {
                if (residual[vertex * MAX_VERTICES + next] > 0 && level[next] < 0) {
                    level[next] = level[vertex] + 1;
                    queue[tail++] = next;
                }
            }
        }
        if (level[sink] < 0) break;

        long[MAX_VERTICES] incoming = zeroed, outgoing = zeroed;
        bool[MAX_VERTICES * MAX_VERTICES] active = zeroed;
        bool[MAX_VERTICES] alive = zeroed;
        for (int vertex = 0; vertex < n; vertex += 1)
            alive[vertex] = level[vertex] >= 0 && level[vertex] <= level[sink];
        for (int from = 0; from < n; from += 1) {
            for (int to = 0; to < n; to += 1) {
                int edge = from * MAX_VERTICES + to;
                if (level[from] >= 0 && level[from] < level[sink] &&
                    level[to] == level[from] + 1 && residual[edge] > 0) {
                    active[edge] = true;
                    outgoing[from] += residual[edge];
                    incoming[to] += residual[edge];
                }
            }
        }
        incoming[source] = FLOW_INFINITY;
        outgoing[sink] = FLOW_INFINITY;

        while (true) {
            int reference = -1;
            long least_potential = FLOW_INFINITY + 1;
            for (int vertex = 0; vertex < n; vertex += 1) {
                if (!alive[vertex]) continue;
                long potential = minimum(incoming[vertex], outgoing[vertex]);
                if (potential < least_potential) {
                    least_potential = potential;
                    reference = vertex;
                }
            }
            if (reference < 0) break;
            if (least_potential > 0) {
                total_flow += least_potential;
                push_backward(reference, source, least_potential, n,
                    &residual[0], &active[0], &incoming[0], &outgoing[0]);
                push_forward(reference, sink, least_potential, n,
                    &residual[0], &active[0], &incoming[0], &outgoing[0]);
            }
            remove_vertex(reference, n, &residual[0], &active[0],
                &incoming[0], &outgoing[0], &alive[0]);
        }
    }
    return total_flow;
}
