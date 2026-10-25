// Clean-room port of TSVC s125; see package README for provenance and rights.
module tsvc_s125_matrix_flattened_fma;

const usz MAX_N = 8;
const usz MAX_CELLS = MAX_N * MAX_N;
const usz MAX_INPUT_LENGTH = 1 + 3 * MAX_CELLS;

fn void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s125_matrix_flattened_fma(long* input, usz length, uchar* output, usz capacity) @export("tsvc_s125_matrix_flattened_fma") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    usz cells = n * n;
    if (length != 1 + 3 * cells) return -1;
    long[MAX_CELLS] aa, bb, cc, result;
    for (usz i = 0; i < cells; i++) {
        aa[i] = input[1 + i];
        bb[i] = input[1 + cells + i];
        cc[i] = input[1 + 2 * cells + i];
        if (aa[i] < -100 || aa[i] > 100 || bb[i] < -100 || bb[i] > 100 ||
            cc[i] < -100 || cc[i] > 100) return -1;
    }
    usz output_bytes = 8 * cells;
    if (output == null || capacity < output_bytes) return -2;
    usz k = 0;
    for (usz i = 0; i < n; i++) {
        for (usz j = 0; j < n; j++) {
            result[k] = aa[k] + bb[k] * cc[k];
            k++;
        }
    }
    for (usz i = 0; i < cells; i++) store_i64_le(output, 8 * i, result[i]);
    return (long)cells;
}
