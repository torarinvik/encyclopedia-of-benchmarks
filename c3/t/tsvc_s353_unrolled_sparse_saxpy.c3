// Clean-room port of TSVC s353; see package README for provenance and rights.
module tsvc_s353_unrolled_sparse_saxpy;

const usz MAX_N = 20;
const usz MAX_INPUT_LENGTH = 2 + 3 * MAX_N;

fn void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s353_unrolled_sparse_saxpy(long* input, usz length, uchar* output, usz capacity) @export("tsvc_s353_unrolled_sparse_saxpy") {
    if (input == null || length < 17 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 5 || input[0] > (long)MAX_N || input[0] % 5 != 0) return -1;
    usz n = (usz)input[0];
    if (length != 2 + 3 * n) return -1;
    long alpha = input[1];
    if (alpha < -8 || alpha > 8) return -1;
    long[MAX_N] a, b, indices;
    for (usz i = 0; i < n; i++) {
        a[i] = input[2 + i];
        b[i] = input[2 + n + i];
        indices[i] = input[2 + 2 * n + i];
        if (a[i] < -1000000 || a[i] > 1000000 || b[i] < -1000000 || b[i] > 1000000 ||
            indices[i] < 0 || indices[i] >= (long)n) return -1;
    }
    if (output == null || capacity < 8 * n) return -2;
    for (usz i = 0; i < n; i += 5) {
        a[i] += alpha * b[(usz)indices[i]];
        a[i + 1] += alpha * b[(usz)indices[i + 1]];
        a[i + 2] += alpha * b[(usz)indices[i + 2]];
        a[i + 3] += alpha * b[(usz)indices[i + 3]];
        a[i + 4] += alpha * b[(usz)indices[i + 4]];
    }
    for (usz i = 0; i < n; i++) store_i64_le(output, 8 * i, a[i]);
    return (long)n;
}
