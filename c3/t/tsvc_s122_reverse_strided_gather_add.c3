// Clean-room port of TSVC s122; see package README for provenance and rights.
module tsvc_s122_reverse_strided_gather_add;

const usz MAX_N = 32;

fn void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s122_reverse_strided_gather_add(long* input, usz length,
        uchar* output, usz capacity) @export("tsvc_s122_reverse_strided_gather_add") {
    if (input == null || length < 5 || length > 67) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (input[1] < 1 || input[1] > (long)n || input[2] < 1 || input[2] > (long)n) return -1;
    if (length != 3 + 2 * n) return -1;
    usz start = (usz)input[1];
    usz stride = (usz)input[2];
    long[MAX_N] a, b;
    for (usz i = 0; i < n; i++) {
        a[i] = input[3 + i];
        b[i] = input[3 + n + i];
        if (a[i] < -100 || a[i] > 100 || b[i] < -100 || b[i] > 100) return -1;
    }
    if (output == null || capacity < 8 * n) return -2;
    usz j = 1, k = 0;
    for (usz i = start - 1; i < n; i += stride) {
        k += j;
        a[i] += b[n - k];
    }
    for (usz i = 0; i < n; i++) store_i64_le(output, 8 * i, a[i]);
    return (long)n;
}
