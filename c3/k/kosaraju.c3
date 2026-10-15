module kosaraju;

const usz MAX_VERTEX_COUNT = 40;
const usz MAX_EDGE_COUNT = 2047;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGE_COUNT;

fn void fill_order(ulong* adjacency, bool* visited, usz* order, usz* order_length,
    usz vertex_count, usz vertex) {
    visited[vertex] = true;
    for (usz neighbor = 0; neighbor < vertex_count; neighbor++) {
        if ((adjacency[vertex] & (1ul << (ulong)neighbor)) != 0ul && !visited[neighbor])
            fill_order(adjacency, visited, order, order_length, vertex_count, neighbor);
    }
    order[*order_length] = vertex;
    (*order_length)++;
}

fn void collect_component(ulong* transpose, bool* visited, long* component_id,
    usz vertex_count, usz vertex, long id) {
    visited[vertex] = true;
    component_id[vertex] = id;
    for (usz neighbor = 0; neighbor < vertex_count; neighbor++) {
        if ((transpose[vertex] & (1ul << (ulong)neighbor)) != 0ul && !visited[neighbor])
            collect_component(transpose, visited, component_id, vertex_count, neighbor, id);
    }
}

fn long kosaraju(long* input, usz length, char* output, usz output_capacity)
    @export("kosaraju") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH || input[0] < 0 ||
        input[0] > (long)MAX_VERTEX_COUNT || input[1] < 0 || input[1] > (long)MAX_EDGE_COUNT) return -1;
    usz vertex_count = (usz)input[0];
    usz edge_count = (usz)input[1];
    if (length != 2 + 2 * edge_count) return -1;
    ulong[MAX_VERTEX_COUNT] adjacency, transpose;
    for (usz vertex = 0; vertex < MAX_VERTEX_COUNT; vertex++) {
        adjacency[vertex] = 0ul;
        transpose[vertex] = 0ul;
    }
    for (usz edge = 0; edge < edge_count; edge++) {
        long from_value = input[2 + 2 * edge];
        long to_value = input[3 + 2 * edge];
        if (from_value < 0 || to_value < 0 || (ulong)from_value >= (ulong)vertex_count ||
            (ulong)to_value >= (ulong)vertex_count) return -1;
        usz from = (usz)from_value;
        usz to = (usz)to_value;
        adjacency[from] |= 1ul << (ulong)to;
        transpose[to] |= 1ul << (ulong)from;
    }
    bool[MAX_VERTEX_COUNT] visited;
    usz[MAX_VERTEX_COUNT] order;
    for (usz vertex = 0; vertex < MAX_VERTEX_COUNT; vertex++) visited[vertex] = false;
    usz order_length = 0;
    for (usz vertex = 0; vertex < vertex_count; vertex++)
        if (!visited[vertex]) fill_order(&adjacency[0], &visited[0], &order[0], &order_length, vertex_count, vertex);
    for (usz vertex = 0; vertex < MAX_VERTEX_COUNT; vertex++) visited[vertex] = false;
    long[MAX_VERTEX_COUNT] component_id;
    for (usz vertex = 0; vertex < MAX_VERTEX_COUNT; vertex++) component_id[vertex] = -1;
    usz component_count = 0;
    for (usz index = order_length; index > 0; index--) {
        usz vertex = order[index - 1];
        if (!visited[vertex]) {
            collect_component(&transpose[0], &visited[0], &component_id[0], vertex_count, vertex, (long)component_count);
            component_count++;
        }
    }
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
