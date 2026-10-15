module remove_nth_from_end;

const MAX_LIST_LENGTH = 1024;
const NONE = MAX_LIST_LENGTH;

// Remove a node by one-based distance from the tail in an index-based list.
fn long remove_nth_node_from_end_of_list(long* input, usz length,
        char* output, usz output_capacity) @export("remove_nth_node_from_end_of_list") {
    if (input == null || length < 2 || length > MAX_LIST_LENGTH + 1) { return -1; }
    usz list_length = length - 1;
    for (usz index = 0; index < list_length; index++) {
        if (input[index + 1] < -2147483648L || input[index + 1] > 2147483647L) { return -1; }
    }
    if (input[0] < 1 || (ulong)input[0] > list_length) { return -1; }

    usz[MAX_LIST_LENGTH] next_node;
    for (usz index = 0; index < list_length; index++) {
        next_node[index] = index + 1 < list_length ? index + 1 : NONE;
    }
    usz node = 0;
    usz counted = 0;
    while (node != NONE) {
        node = next_node[node];
        counted++;
    }
    if (counted != list_length) { return -1; }

    usz steps_to_target = counted - (usz)input[0];
    usz before = NONE;
    node = 0;
    for (usz step = 0; step < steps_to_target; step++) {
        before = node;
        node = next_node[node];
    }
    usz head = before == NONE ? next_node[node] : 0;
    if (before != NONE) { next_node[before] = next_node[node]; }

    usz output_count = counted - 1;
    usz output_bytes = output_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) { return -2; }
    node = head;
    usz written = 0;
    while (node != NONE) {
        uint bits = (uint)(int)input[node + 1];
        for (usz byte = 0; byte < 4; byte++) {
            output[written * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
        }
        node = next_node[node];
        written++;
    }
    return written == output_count ? (long)written : -1;
}
