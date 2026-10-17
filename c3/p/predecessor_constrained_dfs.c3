module predecessor_constrained_dfs;

const usz MAX_NODES = 16;
const usz MAX_INPUT_VALUES = 2 + MAX_NODES * MAX_NODES;
const usz MAX_EVENTS = MAX_NODES + MAX_NODES * (MAX_NODES - 1) / 2;

fn bool visit_node(usz node, usz count, bool* adjacent, bool* predecessors,
        bool* visited, long* events, usz* event_count, long* next_order) {
    if (event_count[0] >= MAX_EVENTS) return false;
    visited[node] = true;
    usz index = 3 * event_count[0];
    events[index] = 1; events[index + 1] = (long)node; events[index + 2] = next_order[0];
    event_count[0] += 1; next_order[0] += 1;
    for (usz child = 0; child < count; child++) {
        if (!adjacent[node * MAX_NODES + child] || visited[child]) continue;
        bool all_visited = true;
        for (usz parent = 0; parent < count; parent++)
            if (predecessors[child * MAX_NODES + parent] && !visited[parent]) { all_visited = false; break; }
        if (all_visited) {
            if (!visit_node(child, count, adjacent, predecessors, visited, events, event_count, next_order)) return false;
        } else {
            if (event_count[0] >= MAX_EVENTS) return false;
            index = 3 * event_count[0];
            events[index] = 0; events[index + 1] = (long)child; events[index + 2] = -1;
            event_count[0] += 1;
        }
    }
    return true;
}

fn void write_i32_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 4; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long predecessor_constrained_dfs(long* input, usz length, char* output,
                                     usz output_capacity) @export("predecessor_constrained_dfs") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long raw_count = input[0], raw_start = input[1];
    if (raw_count < 1 || raw_count > (long)MAX_NODES || raw_start < 0 || raw_start >= raw_count ||
        length != 2 + (usz)raw_count * (usz)raw_count) return -1;
    usz count = (usz)raw_count;
    bool[MAX_NODES * MAX_NODES] adjacent, predecessors;
    usz[MAX_NODES] indegree, queue;
    for (usz i = 0; i < MAX_NODES * MAX_NODES; i++) { adjacent[i] = false; predecessors[i] = false; }
    for (usz i = 0; i < MAX_NODES; i++) indegree[i] = 0;
    for (usz from = 0; from < count; from++) {
        for (usz to = 0; to < count; to++) {
            long bit = input[2 + from * count + to];
            if ((bit != 0 && bit != 1) || (from == to && bit != 0)) return -1;
            if (bit == 1) { adjacent[from * MAX_NODES + to] = true; predecessors[to * MAX_NODES + from] = true; indegree[to] += 1; }
        }
    }
    usz head = 0, tail = 0;
    for (usz node = 0; node < count; node++) if (indegree[node] == 0) queue[tail++] = node;
    while (head < tail) {
        usz node = queue[head++];
        for (usz child = 0; child < count; child++) {
            if (adjacent[node * MAX_NODES + child]) {
                indegree[child] -= 1;
                if (indegree[child] == 0) queue[tail++] = child;
            }
        }
    }
    if (tail != count) return -1;
    bool[MAX_NODES] visited;
    long[MAX_EVENTS * 3] events;
    for (usz node = 0; node < MAX_NODES; node++) visited[node] = false;
    usz event_count = 0;
    long next_order = 0;
    if (!visit_node((usz)raw_start, count, &adjacent[0], &predecessors[0], &visited[0], &events[0], &event_count, &next_order)) return -1;
    usz byte_count = 12 * event_count;
    if (output == null || output_capacity < byte_count) return -2;
    for (usz event = 0; event < event_count; event++) {
        usz index = 3 * event;
        write_i32_le(output, 12 * event, events[index]);
        write_i32_le(output, 12 * event + 4, events[index + 1]);
        write_i32_le(output, 12 * event + 8, events[index + 2]);
    }
    return (long)byte_count;
}
