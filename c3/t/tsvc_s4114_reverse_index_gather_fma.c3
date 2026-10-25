// Clean-room bounded port of TSVC s4114; see package README for provenance.
module tsvc_s4114_reverse_index_gather_fma;

const usz MAX_N = 64;

void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s4114_reverse_index_gather_fma(long* input, usz length,
        uchar* output, usz capacity) @export("tsvc_s4114_reverse_index_gather_fma") {
    if (input == null || length < 5 || length > 257) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != 1 + 4 * n) return -1;
    usz ip_offset = 1, b_offset = 1 + n;
    usz c_offset = 1 + 2 * n, d_offset = 1 + 3 * n;
    for (usz i = 0; i < n; i++) {
        if (input[ip_offset + i] < 0 || input[ip_offset + i] >= (long)n) return -1;
        if (input[b_offset + i] < -2 || input[b_offset + i] > 2 ||
                input[c_offset + i] < -2 || input[c_offset + i] > 2 ||
                input[d_offset + i] < -2 || input[d_offset + i] > 2) return -1;
    }
    if (output == null || capacity < 8 * n) return -2;
    for (usz i = 0; i < n; i++) {
        usz gathered = n - 1 - (usz)input[ip_offset + i];
        long value = input[b_offset + i] + input[c_offset + gathered] * input[d_offset + i];
        store_i64_le(output, 8 * i, value);
    }
    return (long)n;
}
