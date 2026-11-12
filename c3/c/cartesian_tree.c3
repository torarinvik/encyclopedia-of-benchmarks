module cartesian_tree;

const usz MAX_N = 128;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long cartesian_tree(long* input, usz length, char* output, usz capacity)
    @export("cartesian_tree") {
    if (input == null || length < 2 || length > 1 + MAX_N) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != n + 1) return -1;

    usz[MAX_N] stack;
    long[MAX_N] parent;
    for (usz i = 0; i < n; i += 1) {
        long key = input[i + 1];
        if (key < 0 || key > 1000000000) return -1;
        parent[i] = (long)i;
    }

    usz stack_size = 0;
    for (usz i = 0; i < n; i += 1) {
        usz last = MAX_N;
        while (stack_size > 0 && input[stack[stack_size - 1] + 1] > input[i + 1]) {
            stack_size -= 1;
            last = stack[stack_size];
        }
        if (stack_size > 0) parent[i] = (long)stack[stack_size - 1];
        if (last < MAX_N) parent[last] = (long)i;
        stack[stack_size] = i;
        stack_size += 1;
    }

    usz output_bytes = n * 8;
    if (output == null || capacity < output_bytes) return -2;
    for (usz i = 0; i < n; i += 1) store_i64_le(output, i * 8, parent[i]);
    return (long)output_bytes;
}
