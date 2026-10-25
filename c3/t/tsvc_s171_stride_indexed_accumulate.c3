// Clean-room bounded port of TSVC s171; see package README for provenance.
module tsvc_s171_stride_indexed_accumulate;

const usz MAX_N = 32;
const usz MAX_STRIDE = 4;

void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s171_stride_indexed_accumulate(long* input, usz length,
        uchar* output, usz capacity) @export("tsvc_s171_stride_indexed_accumulate") {
    if (input == null || length < 4 || length > 159) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N ||
            input[1] < 1 || input[1] > (long)MAX_STRIDE) return -1;
    usz n = (usz)input[0], stride = (usz)input[1];
    usz a_length = 1 + (n - 1) * stride;
    if (length != 2 + a_length + n) return -1;
    for (usz i = 0; i < a_length + n; i++) {
        if (input[2 + i] < -8 || input[2 + i] > 8) return -1;
    }
    if (output == null || capacity < 8 * a_length) return -2;
    for (usz i = 0; i < a_length; i++) store_i64_le(output, 8 * i, input[2 + i]);
    usz b_offset = 2 + a_length;
    for (usz i = 0; i < n; i++) {
        usz destination = i * stride;
        store_i64_le(output, 8 * destination, input[2 + destination] + input[b_offset + i]);
    }
    return (long)a_length;
}
