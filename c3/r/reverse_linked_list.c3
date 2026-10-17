module reverse_linked_list;

const usz MAX_N = 256;
const usz MAX_INPUT_LENGTH = 257;

fn void store_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long reverse_linked_list(long* input, usz length, char* output, usz capacity) @export("reverse_linked_list") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != n + 1) return -1;
    usz output_bytes = 8 * n;
    if (output == null || capacity < output_bytes) return -2;

    long[MAX_N] nodes;
    long[MAX_N] next;
    long[MAX_N] previous_link;
    for (usz i = 0; i < n; i++) {
        nodes[i] = input[i + 1];
        next[i] = i + 1 < n ? (long)(i + 1) : -1;
        previous_link[i] = i > 0 ? (long)(i - 1) : -1;
    }
    long previous = -1, current = 0;
    while (current >= 0) {
        long next_node = next[(usz)current];
        next[(usz)current] = previous;
        previous_link[(usz)current] = next_node;
        previous = current;
        current = next_node;
    }
    long node = previous, expected_previous = -1;
    long[MAX_N] result;
    for (usz i = 0; i < n; i++) {
        if (node < 0 || previous_link[(usz)node] != expected_previous) return -1;
        result[i] = nodes[(usz)node];
        expected_previous = node;
        node = next[(usz)node];
    }
    if (node >= 0) return -1;
    for (usz i = 0; i < n; i++) store_i64_le(result[i], output, i * 8);
    return (long)output_bytes;
}
