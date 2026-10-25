// Clean-room port of TSVC s453; see package README for provenance and rights.
module tsvc_s453_recurrence_weighted_scale;

const usz MAX_N = 32;

fn void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s453_recurrence_weighted_scale(long* input, usz length,
        uchar* output, usz capacity) @export("tsvc_s453_recurrence_weighted_scale") {
    if (input == null || length < 2 || length > 33) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != 1 + n) return -1;
    long[MAX_N] b, a;
    for (usz i = 0; i < n; i++) {
        b[i] = input[1 + i];
        if (b[i] < -100 || b[i] > 100) return -1;
    }
    if (output == null || capacity < 8 * n) return -2;
    long s = 0;
    for (usz i = 0; i < n; i++) {
        s += 2;
        a[i] = s * b[i];
    }
    for (usz i = 0; i < n; i++) store_i64_le(output, 8 * i, a[i]);
    return (long)n;
}
