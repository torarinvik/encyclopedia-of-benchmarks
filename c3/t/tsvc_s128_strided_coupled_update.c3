// Clean-room port of TSVC s128; see package README for provenance and rights.
module tsvc_s128_strided_coupled_update;

const usz MAX_N = 16;
const usz MAX_INPUT_LENGTH = 1 + 5 * MAX_N;

fn void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s128_strided_coupled_update(long* input, usz length, uchar* output, usz capacity) @export("tsvc_s128_strided_coupled_update") {
    if (input == null || length < 6 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    usz b_count = 2 * n;
    if (length != 1 + 5 * n) return -1;
    long[MAX_N] a, d;
    long[2 * MAX_N] b, c;
    for (usz i = 0; i < b_count; i++) {
        b[i] = input[1 + i];
        c[i] = input[1 + b_count + i];
        if (b[i] < -100 || b[i] > 100 || c[i] < -100 || c[i] > 100) return -1;
    }
    for (usz i = 0; i < n; i++) {
        d[i] = input[1 + 2 * b_count + i];
        if (d[i] < -100 || d[i] > 100) return -1;
    }
    usz output_values = 3 * n;
    usz output_bytes = 8 * output_values;
    if (output == null || capacity < output_bytes) return -2;
    long j = -1;
    for (usz i = 0; i < n; i++) {
        usz k = (usz)(j + 1);
        a[i] = b[k] - d[i];
        j = (long)k + 1;
        b[k] = a[i] + c[k];
    }
    for (usz i = 0; i < n; i++) store_i64_le(output, 8 * i, a[i]);
    for (usz i = 0; i < b_count; i++) store_i64_le(output, 8 * (n + i), b[i]);
    return (long)output_values;
}
