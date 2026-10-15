module tarjan_scc;

const usz MAX_VERTEX_COUNT = 40;
const usz MAX_EDGE_COUNT = 2047;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGE_COUNT;

fn void visit_vertex(ulong* adjacency, bool* on_stack, usz* stack, usz* stack_length,
    long* discovery, long* low, long* component_id, usz vertex_count, usz vertex,
    usz* time, usz* component_count) {
    discovery[vertex] = (long)(*time);
    low[vertex] = (long)(*time);
    (*time)++;
    on_stack[vertex] = true;
    stack[*stack_length] = vertex;
    (*stack_length)++;
    for (usz neighbor = 0; neighbor < vertex_count; neighbor++) {
        if ((adjacency[vertex] & (1ul << (ulong)neighbor)) == 0ul) continue;
        if (discovery[neighbor] == -1) {
            visit_vertex(adjacency, on_stack, stack, stack_length, discovery, low, component_id,
                vertex_count, neighbor, time, component_count);
            if (low[neighbor] < low[vertex]) low[vertex] = low[neighbor];
        } else if (on_stack[neighbor] && discovery[neighbor] < low[vertex]) {
            low[vertex] = discovery[neighbor];
        }
    }
    if (low[vertex] == discovery[vertex]) {
        while (*stack_length > 0) {
            (*stack_length)--;
            usz member = stack[*stack_length];
            on_stack[member] = false;
            component_id[member] = (long)(*component_count);
            if (member == vertex) break;
        }
        (*component_count)++;
    }
}

fn long tarjan_scc(long* input, usz length, char* output, usz output_capacity)
    @export("tarjan_scc") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH || input[0] < 0 ||
        input[0] > (long)MAX_VERTEX_COUNT || input[1] < 0 || input[1] > (long)MAX_EDGE_COUNT) return -1;
    usz vertex_count = (usz)input[0];
    usz edge_count = (usz)input[1];
    if (length != 2 + 2 * edge_count) return -1;
    ulong[MAX_VERTEX_COUNT] adjacency;
    bool[MAX_VERTEX_COUNT] on_stack;
    usz[MAX_VERTEX_COUNT] stack;
    long[MAX_VERTEX_COUNT] discovery, low, component_id;
    for (usz vertex = 0; vertex < MAX_VERTEX_COUNT; vertex++) {
        adjacency[vertex] = 0ul;
        on_stack[vertex] = false;
        discovery[vertex] = -1;
        low[vertex] = 0;
        component_id[vertex] = -1;
    }
    for (usz edge = 0; edge < edge_count; edge++) {
        long from_value = input[2 + 2 * edge];
        long to_value = input[3 + 2 * edge];
        if (from_value < 0 || to_value < 0 || (ulong)from_value >= (ulong)vertex_count ||
            (ulong)to_value >= (ulong)vertex_count) return -1;
        usz from = (usz)from_value;
        usz to = (usz)to_value;
        adjacency[from] |= 1ul << (ulong)to;
    }
    usz stack_length = 0;
    usz time = 0;
    usz component_count = 0;
    for (usz vertex = 0; vertex < vertex_count; vertex++)
        if (discovery[vertex] == -1)
            visit_vertex(&adjacency[0], &on_stack[0], &stack[0], &stack_length,
                &discovery[0], &low[0], &component_id[0], vertex_count, vertex, &time, &component_count);
    usz output_length = 1 + vertex_count + component_count;
    if (output_capacity < output_length || (output_length != 0 && output == null)) return -2;
    output[0] = (char)component_count;
    usz position = 1;
    for (usz first = 0; first < vertex_count; first++) {
        long id = component_id[first];
        bool emitted = false;
        for (usz earlier = 0; earlier < first; earlier++)
            if (component_id[earlier] == id) emitted = true;
        if (emitted) continue;
        usz component_size = 0;
        for (usz vertex = first; vertex < vertex_count; vertex++)
            if (component_id[vertex] == id) component_size++;
        output[position] = (char)component_size;
        position++;
        for (usz vertex = first; vertex < vertex_count; vertex++)
            if (component_id[vertex] == id) {
                output[position] = (char)vertex;
                position++;
            }
    }
    return (long)output_length;
}
