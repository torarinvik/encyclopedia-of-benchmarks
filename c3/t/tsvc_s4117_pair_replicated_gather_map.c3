// Clean-room bounded port of TSVC s4117; see package README for provenance.
module tsvc_s4117_pair_replicated_gather_map;

const usz MAX_N = 64;

void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s4117_pair_replicated_gather_map(long* input, usz length,
        uchar* output, usz capacity) @export("tsvc_s4117_pair_replicated_gather_map") {
    if (input == null || length < 4 || length > 161) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    usz c_length = (n + 1) / 2;
    if (length != 1 + 2 * n + c_length) return -1;
    for (usz i = 1; i < length; i++) {
        if (input[i] < -2 || input[i] > 2) return -1;
    }
    if (output == null || capacity < 8 * n) return -2;
    usz b_offset = 1;
    usz c_offset = 1 + n;
    usz d_offset = c_offset + c_length;
    for (usz i = 0; i < n; i++) {
        long value = input[b_offset + i] + input[c_offset + i / 2] * input[d_offset + i];
        store_i64_le(output, 8 * i, value);
    }
    return (long)n;
}
