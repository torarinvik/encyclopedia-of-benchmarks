module remove_all_dups_sorted;

const MAX_NODES = 1024;
const MAX_LINKS = 1025;

fn usz remove_duplicate_runs(long* input, usz* next_node, usz node, usz none) {
    if (node == none) return none;
    usz next = next_node[node];
    if (next != none && input[node] == input[next]) {
        long duplicate = input[node];
        usz after_run = next;
        while (after_run != none && input[after_run] == duplicate) {
            after_run = next_node[after_run];
        }
        return remove_duplicate_runs(input, next_node, after_run, none);
    }
    next_node[node] = remove_duplicate_runs(input, next_node, next, none);
    return node;
}

fn long remove_all_duplicates_from_sorted_list(long* input, usz length, char* output,
        usz output_capacity) @export("remove_all_duplicates_from_sorted_list") {
    if (length > MAX_NODES || (length != 0 && input == null)) return -1;
    for (usz index = 0; index < length; index++) {
        long value = input[index];
        if (value < -2147483648L || value > 2147483647L
            || (index != 0 && input[index - 1] > value)) return -1;
    }
    usz[MAX_LINKS] next_node;
    for (usz index = 0; index < length; index++) next_node[index] = index + 1;
    next_node[length] = length;
    usz head = remove_duplicate_runs(input, &next_node[0], 0, length);
    usz survivor_count = 0;
    for (usz node = head; node != length; node = next_node[node]) survivor_count++;
    usz output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) return -2;
    usz written = 0;
    for (usz node = head; node != length; node = next_node[node]) {
        uint bits = (uint)(int)input[node];
        for (usz byte = 0; byte < 4; byte++) {
            output[written * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
        }
        written++;
    }
    return written == survivor_count ? (long)written : -1;
}
