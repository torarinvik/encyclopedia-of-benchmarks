module depth_first_search_target_route;

const usz MAX_NODES = 64;
const usz MAX_EDGES = 94;
const usz MAX_INPUT_LENGTH = 4 + MAX_NODES + 2 * MAX_EDGES;
const usz MAX_OUTPUT_BYTES = 128;

fn long depth_first_search_target_route(long* values, usz length, char* output, usz output_capacity)
    @export("depth_first_search_target_route")
{
    if (values == null || length < 5 || length > MAX_INPUT_LENGTH) return -2;
    if (values[0] < 1 || values[0] > (long)MAX_NODES
        || values[1] < 0 || values[1] > 255 || values[2] < 0 || values[2] > 255) return -2;
    usz node_count = (usz)values[0];
    long start_label = values[1];
    long target_label = values[2];
    usz edge_count_position = 3 + node_count;
    if (edge_count_position >= length) return -2;

    long[MAX_NODES] labels;
    usz start_index = node_count;
    for (usz index = 0; index < node_count; index++) {
        long label = values[3 + index];
        if (label < 0 || label > 255) return -2;
        for (usz prior = 0; prior < index; prior++) if (labels[prior] == label) return -2;
        labels[index] = label;
        if (label == start_label) start_index = index;
    }
    if (start_index == node_count) return -2;

    long edge_count_value = values[edge_count_position];
    if (edge_count_value < 0 || edge_count_value > (long)MAX_EDGES) return -2;
    usz edge_count = (usz)edge_count_value;
    if (length != edge_count_position + 1 + 2 * edge_count) return -2;

    ulong[MAX_NODES] adjacency;
    for (usz index = 0; index < node_count; index++) adjacency[index] = 0;
    for (usz edge = 0; edge < edge_count; edge++) {
        long left_label = values[edge_count_position + 1 + 2 * edge];
        long right_label = values[edge_count_position + 2 + 2 * edge];
        usz left = node_count;
        usz right = node_count;
        for (usz index = 0; index < node_count; index++) {
            if (labels[index] == left_label) left = index;
            if (labels[index] == right_label) right = index;
        }
        if (left == node_count || right == node_count) return -2;
        adjacency[left] |= 1ul << (ulong)right;
        adjacency[right] |= 1ul << (ulong)left;
    }

    usz[MAX_NODES] stack;
    usz stack_length = 1;
    stack[0] = start_index;
    char[MAX_OUTPUT_BYTES] route;
    usz route_length = 0;
    while (stack_length != 0) {
        stack_length--;
        usz current = stack[stack_length];
        if (route_length == MAX_OUTPUT_BYTES) return -2;
        route[route_length] = (char)labels[current];
        route_length++;
        for (usz neighbor = 0; neighbor < node_count; neighbor++) {
            ulong bit = 1ul << (ulong)neighbor;
            if ((adjacency[current] & bit) != 0) {
                usz pending = 0;
                while (pending < stack_length && stack[pending] != neighbor) pending++;
                if (pending == stack_length) {
                    stack[stack_length] = neighbor;
                    stack_length++;
                }
            }
            adjacency[current] &= ~bit;
            adjacency[neighbor] &= ~(1ul << (ulong)current);
        }
        if (labels[current] == target_label) {
            if (output_capacity < route_length || (route_length != 0 && output == null)) return -2;
            for (usz index = 0; index < route_length; index++) output[index] = route[index];
            return (long)route_length;
        }
    }
    return 0;
}
