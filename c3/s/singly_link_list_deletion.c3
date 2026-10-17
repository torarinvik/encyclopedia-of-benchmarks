module singly_link_list_deletion;

const usz MAX_N = 64;
const long I32_MIN_VALUE = -2147483648;
const long I32_MAX_VALUE = 2147483647;

fn void store_i32_le(char* output, usz offset, long value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long singly_link_list_deletion(long* input, usz length, char* output, usz capacity)
    @export("singly_link_list_deletion") {
    if (input == null || length < 2 || length > 66) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != n + 2 || input[1] < 1 || input[1] > n_value) return -1;
    for (usz i = 0; i < n; i++)
        if (input[i + 2] < I32_MIN_VALUE || input[i + 2] > I32_MAX_VALUE) return -1;
    usz bytes = 4 * (n - 1);
    if (output == null || capacity < bytes) return -2;

    int[MAX_N] nodes;
    long[MAX_N] next;
    for (usz i = 0; i < n; i++) {
        nodes[i] = (int)input[i + 2];
        next[i] = if i + 1 < n then (long)(i + 1) else -1;
    }
    long head = 0;
    usz position = (usz)input[1];
    if (position == 1) head = next[(usz)head];
    else {
        long previous = head;
        for (usz i = 2; i < position; i++) previous = next[(usz)previous];
        long removed = next[(usz)previous];
        next[(usz)previous] = next[(usz)removed];
    }
    long node = head;
    for (usz i = 0; i < n - 1; i++) {
        store_i32_le(output, i * 4, (long)nodes[(usz)node]);
        if (i + 1 < n - 1) node = next[(usz)node];
    }
    (long)bytes
}
