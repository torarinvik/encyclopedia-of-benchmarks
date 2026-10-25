// Clean-room bounded port of TSVC s332; see package README for provenance.
module tsvc_s332_first_above_threshold;

const usz MAX_N = 256;

fn void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s332_first_above_threshold(long* input, usz length,
        uchar* output, usz capacity) @export("tsvc_s332_first_above_threshold") {
    if (input == null || length < 3 || length > 258) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N || input[1] < -1000000 || input[1] > 1000000) return -1;
    usz n = (usz)input[0];
    long threshold = input[1];
    if (length != 2 + n) return -1;
    long[MAX_N] values;
    for (usz i = 0; i < n; i++) {
        values[i] = input[2 + i];
        if (values[i] < -1000000 || values[i] > 1000000) return -1;
    }
    if (output == null || capacity < 16) return -2;
    long index = -2, value = -1;
    for (usz i = 0; i < n; i++) {
        if (values[i] > threshold) {
            index = (long)i;
            value = values[i];
            break;
        }
    }
    store_i64_le(output, 0, index);
    store_i64_le(output, 8, value);
    return 2;
}
