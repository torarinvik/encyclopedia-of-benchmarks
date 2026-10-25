// Clean-room port of TSVC s127; see package README for provenance and rights.
module tsvc_s127_fixed_pair_expansion;

const usz MAX_N = 32;
const usz MAX_INPUT_LENGTH = 1 + 4 * MAX_N;

fn void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s127_fixed_pair_expansion(long* input, usz length, uchar* output, usz capacity) @export("tsvc_s127_fixed_pair_expansion") {
    if (input == null || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != 1 + 4 * n) return -1;
    long[MAX_N] b, c, d, e;
    long[2 * MAX_N] a;
    for (usz i = 0; i < n; i++) {
        b[i] = input[1 + i];
        c[i] = input[1 + n + i];
        d[i] = input[1 + 2 * n + i];
        e[i] = input[1 + 3 * n + i];
        if (b[i] < -100 || b[i] > 100 || c[i] < -100 || c[i] > 100 ||
            d[i] < -100 || d[i] > 100 || e[i] < -100 || e[i] > 100) return -1;
    }
    usz output_values = 2 * n;
    usz output_bytes = 8 * output_values;
    if (output == null || capacity < output_bytes) return -2;
    long j = -1;
    for (usz i = 0; i < n; i++) {
        j++;
        a[(usz)j] = b[i] + c[i] * d[i];
        j++;
        a[(usz)j] = b[i] + d[i] * e[i];
    }
    for (usz i = 0; i < output_values; i++) store_i64_le(output, 8 * i, a[i]);
    return (long)output_values;
}
