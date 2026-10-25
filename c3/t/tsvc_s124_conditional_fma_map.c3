// Clean-room port of TSVC s124; see package README for provenance and rights.
module tsvc_s124_conditional_fma_map;

const usz MAX_N = 32;
const usz MAX_INPUT_LENGTH = 1 + 4 * MAX_N;

fn void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s124_conditional_fma_map(long* input, usz length, uchar* output, usz capacity) @export("tsvc_s124_conditional_fma_map") {
    if (input == null || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != 1 + 4 * n) return -1;
    long[MAX_N] a, b, c, d, e;
    for (usz i = 0; i < n; i++) {
        b[i] = input[1 + i];
        c[i] = input[1 + n + i];
        d[i] = input[1 + 2 * n + i];
        e[i] = input[1 + 3 * n + i];
        if (b[i] < -100 || b[i] > 100 || c[i] < -100 || c[i] > 100 ||
            d[i] < -100 || d[i] > 100 || e[i] < -100 || e[i] > 100) return -1;
    }
    if (output == null || capacity < 8 * n) return -2;
    long j = -1;
    for (usz i = 0; i < n; i++) {
        if (b[i] > 0) {
            j++;
            a[(usz)j] = b[i] + d[i] * e[i];
        } else {
            j++;
            a[(usz)j] = c[i] + d[i] * e[i];
        }
    }
    for (usz i = 0; i < n; i++) store_i64_le(output, 8 * i, a[i]);
    return (long)n;
}
