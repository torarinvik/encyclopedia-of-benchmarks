// Clean-room port of TSVC s114; see package README for provenance and rights.
module tsvc_s114_transposed_lower_triangle_update;

const usz MAX_N = 16;
const usz MAX_INPUT_LENGTH = 1 + 2 * MAX_N * MAX_N;

fn void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s114_transposed_lower_triangle_update(long* input, usz length, uchar* output, usz capacity) @export("tsvc_s114_transposed_lower_triangle_update") {
    if (input == null || length < 9 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 2 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    usz cells = n * n;
    if (length != 1 + 2 * cells) return -1;
    long[MAX_N * MAX_N] a, b;
    for (usz i = 0; i < cells; i++) {
        a[i] = input[1 + i];
        b[i] = input[1 + cells + i];
        if (a[i] < -1000000 || a[i] > 1000000 || b[i] < -1000000 || b[i] > 1000000) return -1;
    }
    usz bytes = 8 * cells;
    if (output == null || capacity < bytes) return -2;
    for (usz i = 0; i < n; i++)
        for (usz j = 0; j < i; j++)
            a[i * n + j] = a[j * n + i] + b[i * n + j];
    for (usz i = 0; i < cells; i++) store_i64_le(output, 8 * i, a[i]);
    return (long)cells;
}
