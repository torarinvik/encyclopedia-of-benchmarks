// Clean-room bounded port of TSVC s442; see package README for provenance.
module tsvc_s442_indexed_square_accumulate;

const usz MAX_N = 64;
const usz MAX_PASSES = 16;

fn void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s442_indexed_square_accumulate(long* input, usz length,
        uchar* output, usz capacity) @export("tsvc_s442_indexed_square_accumulate") {
    if (input == null || length < 8 || length > 386) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N ||
        input[1] < 1 || input[1] > (long)MAX_PASSES) return -1;
    usz n = (usz)input[0], passes = (usz)input[1];
    if (length != 2 + 6 * n) return -1;
    long[MAX_N] a, b, c, d, e, selector;
    for (usz i = 0; i < n; i++) {
        a[i] = input[2 + i];
        b[i] = input[2 + n + i];
        c[i] = input[2 + 2 * n + i];
        d[i] = input[2 + 3 * n + i];
        e[i] = input[2 + 4 * n + i];
        selector[i] = input[2 + 5 * n + i];
        if (a[i] < -2 || a[i] > 2 || b[i] < -2 || b[i] > 2 ||
            c[i] < -2 || c[i] > 2 || d[i] < -2 || d[i] > 2 ||
            e[i] < -2 || e[i] > 2 || selector[i] < 1 || selector[i] > 4) return -1;
    }
    if (output == null || capacity < 8 * n) return -2;
    for (usz round = 0; round < passes; round++) {
        for (usz i = 0; i < n; i++) {
            long selected = selector[i] == 1 ? b[i] :
                            selector[i] == 2 ? c[i] :
                            selector[i] == 3 ? d[i] : e[i];
            a[i] += selected * selected;
        }
    }
    for (usz i = 0; i < n; i++) store_i64_le(output, 8 * i, a[i]);
    return (long)n;
}
