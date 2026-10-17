module reverse_a_linked_list_using_recusion;

const usz MAX_N = 64;
const long I32_MIN_VALUE = -2147483648;
const long I32_MAX_VALUE = 2147483647;

fn long reverse_links(long* next, long previous, long current) {
    if (next[(usz)current] >= 0) {
        long head = reverse_links(next, current, next[(usz)current]);
        next[(usz)current] = previous;
        next[(usz)previous] = -1;
        return head;
    }
    next[(usz)current] = previous;
    next[(usz)previous] = -1;
    return current;
}

fn void store_i32_le(char* output, usz offset, long value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long reverse_a_linked_list_using_recusion(long* input, usz length, char* output,
                                              usz capacity)
    @export("reverse_a_linked_list_using_recusion") {
    if (input == null || length < 1 || length > 65) return -1;
    long n_value = input[0];
    if (n_value < 2 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != n + 1) return -1;
    for (usz i = 0; i < n; i++)
        if (input[i + 1] < I32_MIN_VALUE || input[i + 1] > I32_MAX_VALUE) return -1;
    usz bytes = 4 * n;
    if (output == null || capacity < bytes) return -2;

    int[MAX_N] nodes;
    long[MAX_N] next;
    for (usz i = 0; i < n; i++) {
        nodes[i] = (int)input[i + 1];
        next[i] = if i + 1 < n then (long)(i + 1) else -1;
    }
    long node = reverse_links(next, 0, next[0]);
    for (usz i = 0; i < n; i++) {
        store_i32_le(output, i * 4, (long)nodes[(usz)node]);
        if (i + 1 < n) node = next[(usz)node];
    }
    return (long)bytes;
}
