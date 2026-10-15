module remove_linked_list_elements;

const usz MAX_NODES = 1024;

fn usz remove_chain(long* input, usz* next_node, usz node, usz none, long target) {
    if (node == none) return none;
    usz next = next_node[node];
    if (input[node + 1] == target) return remove_chain(input, next_node, next, none, target);
    next_node[node] = remove_chain(input, next_node, next, none, target);
    return node;
}

fn long remove_linked_list_elements(long* input, usz length, char* output,
        usz output_capacity) @export("remove_linked_list_elements") {
    if (input == null || length == 0 || length > MAX_NODES + 1) return -1;
    long target = input[0];
    if (target < -2147483648L || target > 2147483647L) return -1;
    usz node_count = length - 1;
    usz[MAX_NODES + 1] next_node;
    for (usz index = 0; index < node_count; index++) {
        long value = input[index + 1];
        if (value < -2147483648L || value > 2147483647L) return -1;
        next_node[index] = index + 1;
    }
    next_node[node_count] = node_count;
    usz head = node_count == 0 ? node_count : 0;
    head = remove_chain(input, &next_node[0], head, node_count, target);
    usz survivor_count = 0;
    for (usz node = head; node != node_count; node = next_node[node]) survivor_count++;
    usz output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) return -2;
    usz written = 0;
    for (usz node = head; node != node_count; node = next_node[node]) {
        uint bits = (uint)(int)input[node + 1];
        for (usz byte = 0; byte < 4; byte++) output[written * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
        written++;
    }
    return written == survivor_count ? (long)written : -1;
}
