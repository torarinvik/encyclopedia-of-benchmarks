module next_smaller_element;
const usz MAX_N = 1024;
fn void put_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) { output[offset+b] = (char)(bits & 255); bits >>= 8; }
}
fn long next_smaller_element(long* input, usz length, char* output, usz capacity) @export("next_smaller_element") {
    if (input == null || length < 1 || input[0] < 0 || input[0] > MAX_N) return -1;
    usz n = (usz)input[0]; if (length != n + 1) return -1;
    for (usz i = 0; i < n; i++) if (input[i+1] < -2147483648L || input[i+1] > 2147483647L) return -1;
    if (capacity < n*8 || (n > 0 && output == null)) return -2;
    long[MAX_N] stack; usz top = 0;
    for (usz i = 0; i < n; i++) {
        long value = input[i+1];
        while (top > 0 && stack[top-1] >= value) top--;
        put_i64_le(top > 0 ? stack[top-1] : -1, output, i*8);
        stack[top++] = value;
    }
    return (long)(n*8);
}
