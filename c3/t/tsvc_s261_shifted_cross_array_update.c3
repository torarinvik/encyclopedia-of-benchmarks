// Clean-room bounded port of TSVC s261; see package README for provenance.
module tsvc_s261_shifted_cross_array_update;

const usz MAX_N = 64;

fn void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s261_shifted_cross_array_update(long* input, usz length,
        uchar* output, usz capacity) @export("tsvc_s261_shifted_cross_array_update") {
    if (input == null || length < 9 || length > 257) return -1;
    if (input[0] < 2 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != 1 + 4 * n) return -1;
    long[MAX_N] a, b, c, d;
    for (usz i = 0; i < n; i++) {
        a[i] = input[1 + i];
        b[i] = input[1 + n + i];
        c[i] = input[1 + 2 * n + i];
        d[i] = input[1 + 3 * n + i];
        if (a[i] < -2 || a[i] > 2 || b[i] < -2 || b[i] > 2 ||
            c[i] < -2 || c[i] > 2 || d[i] < -2 || d[i] > 2) return -1;
    }
    if (output == null || capacity < 16 * n) return -2;
    for (usz i = 1; i < n; i++) {
        long temporary = a[i] + b[i];
        a[i] = temporary + c[i - 1];
        long product = c[i] * d[i];
        c[i] = product;
    }
    for (usz i = 0; i < n; i++) {
        store_i64_le(output, 8 * i, a[i]);
        store_i64_le(output, 8 * (n + i), c[i]);
    }
    return (long)(2 * n);
}
