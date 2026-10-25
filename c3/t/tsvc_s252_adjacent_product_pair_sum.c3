// Clean-room bounded port of TSVC s252; see package README for provenance.
module tsvc_s252_adjacent_product_pair_sum;

const usz MAX_N = 64;

fn void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s252_adjacent_product_pair_sum(long* input, usz length,
        uchar* output, usz capacity) @export("tsvc_s252_adjacent_product_pair_sum") {
    if (input == null || length < 3 || length > 129) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != 1 + 2 * n) return -1;
    long[MAX_N] b, c;
    for (usz i = 0; i < n; i++) {
        b[i] = input[1 + i];
        c[i] = input[1 + n + i];
        if (b[i] < -2 || b[i] > 2 || c[i] < -2 || c[i] > 2) return -1;
    }
    if (output == null || capacity < 8 * n) return -2;
    long previous_product = 0;
    for (usz i = 0; i < n; i++) {
        long product = b[i] * c[i];
        store_i64_le(output, 8 * i, product + previous_product);
        previous_product = product;
    }
    return (long)n;
}
