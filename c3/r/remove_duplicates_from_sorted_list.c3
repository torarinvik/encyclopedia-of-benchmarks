module remove_sorted_list_dups;

const MAX_NODES = 1024;
const MAX_LINKS = 1025;

fn long remove_duplicates_from_sorted_list(long* input, usz length, char* output,
        usz output_capacity) @export("remove_duplicates_from_sorted_list") {
    if (length > MAX_NODES || (length != 0 && input == null)) return -1;
    for (usz index = 0; index < length; index++) {
        long value = input[index];
        if (value < -2147483648L || value > 2147483647L
            || (index != 0 && input[index - 1] > value)) return -1;
    }
    usz[MAX_LINKS] next_node;
    for (usz index = 0; index < length; index++) next_node[index] = index + 1;
    next_node[length] = length;
    usz current = 0;
    while (current != length && next_node[current] != length) {
        usz next = next_node[current];
        if (input[current] == input[next]) {
            next_node[current] = next_node[next];
        } else {
            current = next;
        }
    }
    usz survivor_count = 0;
    for (usz node = 0; node != length; node = next_node[node]) survivor_count++;
    usz output_bytes = survivor_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) return -2;
    usz written = 0;
    for (usz node = 0; node != length; node = next_node[node]) {
        uint bits = (uint)(int)input[node];
        for (usz byte = 0; byte < 4; byte++) {
            output[written * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
        }
        written++;
    }
    return written == survivor_count ? (long)written : -1;
}
