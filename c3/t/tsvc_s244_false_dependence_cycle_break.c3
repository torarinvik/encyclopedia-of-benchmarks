// Clean-room port of TSVC s244; see package README for provenance and rights.
module tsvc_s244_false_dependence_cycle_break;

const usz MAX_N = 32;

fn void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s244_false_dependence_cycle_break(long* input, usz length,
        uchar* output, usz capacity) @export("tsvc_s244_false_dependence_cycle_break") {
    if (input == null || length < 9 || length > 129) return -1;
    if (input[0] < 2 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != 1 + 4 * n) return -1;
    long[MAX_N] a, b, c, d;
    long[MAX_N - 1] trace;
    for (usz i = 0; i < n; i++) {
        a[i] = input[1 + i];
        b[i] = input[1 + n + i];
        c[i] = input[1 + 2 * n + i];
        d[i] = input[1 + 3 * n + i];
        if (a[i] < -2 || a[i] > 2 || b[i] < -2 || b[i] > 2 ||
            c[i] < -2 || c[i] > 2 || d[i] < -2 || d[i] > 2) return -1;
    }
    usz output_values = 3 * n - 1;
    if (output == null || capacity < 8 * output_values) return -2;
    for (usz i = 0; i < n - 1; i++) {
        a[i] = b[i] + c[i] * d[i];
        b[i] = c[i] + b[i];
        a[i + 1] = b[i] + a[i + 1] * d[i];
        trace[i] = a[i + 1];
    }
    usz offset = 0;
    for (usz i = 0; i < n; i++) { store_i64_le(output, 8 * offset, a[i]); offset++; }
    for (usz i = 0; i < n; i++) { store_i64_le(output, 8 * offset, b[i]); offset++; }
    for (usz i = 0; i < n - 1; i++) { store_i64_le(output, 8 * offset, trace[i]); offset++; }
    return (long)output_values;
}
