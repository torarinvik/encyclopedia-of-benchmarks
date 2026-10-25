// Clean-room bounded port of TSVC s1244; see package README for provenance.
module tsvc_s1244_polynomial_neighbor_sum;

const usz MAX_N = 32;

fn void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s1244_polynomial_neighbor_sum(long* input, usz length,
        uchar* output, usz capacity) @export("tsvc_s1244_polynomial_neighbor_sum") {
    if (input == null || length < 9 || length > 129) return -1;
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
    for (usz i = 0; i < n - 1; i++) {
        long old_next_a = a[i + 1];
        a[i] = b[i] + c[i] * c[i] + b[i] * b[i] + c[i];
        d[i] = a[i] + old_next_a;
    }
    for (usz i = 0; i < n; i++) {
        store_i64_le(output, 8 * i, a[i]);
        store_i64_le(output, 8 * (n + i), d[i]);
    }
    return (long)(2 * n);
}
