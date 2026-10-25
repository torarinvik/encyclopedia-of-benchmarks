// Clean-room port of TSVC s1221; see package README for provenance and rights.
module tsvc_s1221_lag4_add_recurrence;

const usz MIN_N = 5;
const usz MAX_N = 32;

fn void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s1221_lag4_add_recurrence(long* input, usz length,
        uchar* output, usz capacity) @export("tsvc_s1221_lag4_add_recurrence") {
    if (input == null || length < 11 || length > 65) return -1;
    if (input[0] < (long)MIN_N || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != 1 + 2 * n) return -1;
    long[MAX_N] a, b;
    for (usz i = 0; i < n; i++) {
        a[i] = input[1 + i];
        b[i] = input[1 + n + i];
        if (a[i] < -10 || a[i] > 10 || b[i] < -10 || b[i] > 10) return -1;
    }
    if (output == null || capacity < 8 * n) return -2;
    for (usz i = 4; i < n; i++) b[i] = b[i - 4] + a[i];
    for (usz i = 0; i < n; i++) store_i64_le(output, 8 * i, b[i]);
    return (long)n;
}
