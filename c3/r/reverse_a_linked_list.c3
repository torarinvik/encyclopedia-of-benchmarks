module reverse_a_linked_list;

const usz MAX_N = 128;
const usz MAX_INPUT_LENGTH = 129;
const long I32_MIN_VALUE = -2147483648;
const long I32_MAX_VALUE = 2147483647;

fn void store_i32_le(long value, char* output, usz offset) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long reverse_a_linked_list(long* input, usz length, char* output, usz capacity) @export("reverse_a_linked_list") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != n + 1) return -1;
    for (usz i = 0; i < n; i++) if (input[i + 1] < I32_MIN_VALUE || input[i + 1] > I32_MAX_VALUE) return -1;
    usz output_bytes = 4 * n;
    if (output == null || capacity < output_bytes) return -2;

    int[MAX_N] nodes;
    long[MAX_N] next;
    long head = -1;
    for (usz i = 0; i < n; i++) {
        nodes[i] = (int)input[i + 1];
        next[i] = -1;
        if (head < 0) head = (long)i;
        else {
            long tail = head;
            while (next[(usz)tail] >= 0) tail = next[(usz)tail];
            next[(usz)tail] = (long)i;
        }
    }
    long previous = -1, current = head;
    while (current >= 0) {
        long next_node = next[(usz)current];
        next[(usz)current] = previous;
        previous = current;
        current = next_node;
    }
    head = previous;
    for (usz index = 0; index < n; index++) {
        long node = head;
        for (usz step = 0; step < index; step++) node = next[(usz)node];
        store_i32_le((long)nodes[(usz)node], output, index * 4);
    }
    return (long)output_bytes;
}
