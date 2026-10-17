module rotate_singly_linked_lists;

const usz MAX_N = 64;
const long I32_MIN_VALUE = -2147483648;
const long I32_MAX_VALUE = 2147483647;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long rotate_singly_linked_lists(long* input, usz length, char* output, usz capacity)
    @export("rotate_singly_linked_lists") {
    if (input == null || length < 2 || length > 66) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_N || input[1] < 0 || input[1] > I32_MAX_VALUE) return -1;
    usz n = (usz)input[0];
    long k = input[1];
    if (length != n + 2) return -1;
    for (usz i = 0; i < n; i++)
        if (input[i + 2] < I32_MIN_VALUE || input[i + 2] > I32_MAX_VALUE) return -1;
    usz bytes = 8 * (n + 1);
    if (output == null || capacity < bytes) return -2;

    int[MAX_N] nodes;
    long[MAX_N] next;
    for (usz i = 0; i < n; i++) {
        nodes[i] = (int)input[i + 2];
        next[i] = if i + 1 < n then (long)(i + 1) else -1;
    }
    long head = if n > 0 then 0 else -1;
    if (n > 1 && k > 0) {
        usz tail = n - 1;
        next[tail] = head;
        usz shift = (usz)(k % (long)n);
        usz steps = n - shift;
        usz new_tail = tail;
        for (usz i = 0; i < steps; i++) new_tail = (usz)next[new_tail];
        head = next[new_tail];
        next[new_tail] = -1;
    }
    store_i64_le(output, 0, (long)n);
    long node = head;
    for (usz i = 0; i < n; i++) {
        store_i64_le(output, 8 + i * 8, (long)nodes[(usz)node]);
        if (i + 1 < n) node = next[(usz)node];
    }
    return (long)bytes;
}
