module delete_middle_node;

const usz MAX_NODES = 1024;

fn long delete_middle_node(long* input, usz length, char* output, usz output_capacity)
        @export("delete_middle_node") {
    if (length > MAX_NODES || (length != 0 && input == null)) return -1;
    for (usz index = 0; index < length; index++) {
        if (input[index] < -2147483648L || input[index] > 2147483647L) return -1;
    }
    if (length <= 1) return 0;

    usz[MAX_NODES + 1] next_node;
    for (usz index = 0; index < length; index++) next_node[index] = index + 1;
    next_node[length] = length;
    usz node_count = 0;
    for (usz cursor = 0; cursor != length; cursor = next_node[cursor]) node_count++;
    usz fast = 0;
    usz slow = 0;
    usz previous = length;
    while (next_node[fast] != length && next_node[next_node[fast]] != length) {
        previous = slow;
        slow = next_node[slow];
        fast = next_node[next_node[fast]];
    }
    if (node_count % 2 == 0) { previous = slow; slow = next_node[slow]; }
    next_node[previous] = next_node[slow];

    usz survivor_count = node_count - 1;
    usz output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) return -2;
    usz written = 0;
    for (usz node = 0; node != length; node = next_node[node]) {
        uint bits = (uint)(int)input[node];
        for (usz byte = 0; byte < 4; byte++) output[written * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
        written++;
    }
    return written == survivor_count ? (long)written : -1;
}
