module sliding_window_maximum;

const MAX_LENGTH = 1024;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long sliding_window_maximum(long* input, usz length, char* output, usz capacity) @export("sliding_window_maximum") {
    if (input == null || length < 2 || length > MAX_LENGTH + 2) return -1;
    long n_value = input[0], k_value = input[1];
    if (n_value < 0 || n_value > MAX_LENGTH || k_value < 1 || k_value > MAX_LENGTH) return -1;
    usz n = (usz)n_value, k = (usz)k_value;
    if (length != n + 2) return -1;
    for (usz i = 0; i < n; i++) if (input[2 + i] < -2147483648 || input[2 + i] > 2147483647) return -1;
    usz windows = n >= k ? n - k + 1 : 0;
    if (capacity < windows * 8 || (windows > 0 && output == null)) return -2;
    usz[MAX_LENGTH] deque;
    usz head = 0, tail = 0, out_index = 0;
    for (usz i = 0; i < n; i++) {
        while (head < tail && deque[head] + k <= i) head++;
        while (head < tail && input[2 + deque[tail - 1]] < input[2 + i]) tail--;
        deque[tail] = i; tail++;
        if (i + 1 >= k) { store_i64_le(output, out_index * 8, input[2 + deque[head]]); out_index++; }
    }
    return (long)windows;
}
