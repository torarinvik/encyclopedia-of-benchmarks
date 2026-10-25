// Clean-room bounded port of TSVC s162; see package README for provenance.
module tsvc_s162_guarded_shifted_fma;

const usz MAX_N = 64;

void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s162_guarded_shifted_fma(long* input, usz length,
        uchar* output, usz capacity) @export("tsvc_s162_guarded_shifted_fma") {
    if (input == null || length < 5 || length > 194) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N || input[1] < 0 || input[1] > 1) return -1;
    usz n = (usz)input[0];
    if (length != 2 + 3 * n) return -1;
    for (usz i = 2; i < length; i++) {
        if (input[i] < -2 || input[i] > 2) return -1;
    }
    if (output == null || capacity < 8 * n) return -2;
    usz a_offset = 2, b_offset = a_offset + n, c_offset = b_offset + n;
    for (usz i = 0; i < n; i++) store_i64_le(output, 8 * i, input[a_offset + i]);
    if (input[1] > 0) {
        for (usz i = 0; i + 1 < n; i++) {
            long value = input[a_offset + i + 1] + input[b_offset + i] * input[c_offset + i];
            store_i64_le(output, 8 * i, value);
        }
    }
    return (long)n;
}
