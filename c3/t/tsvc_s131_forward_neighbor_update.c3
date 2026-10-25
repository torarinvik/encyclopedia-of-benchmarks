module tsvc_s131_forward_neighbor_update;

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_N;
const long MAX_VALUE = 1000000;
const usz MAX_PASSES = 32;

fn bool bounded_value(long value) {
    return value >= -MAX_VALUE && value <= MAX_VALUE;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tsvc_s131_forward_neighbor_update(long* input, usz length, char* output,
        usz output_capacity) @export("tsvc_s131_forward_neighbor_update") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0], passes_raw = input[1];
    if (n_raw < 1 || n_raw > (long)MAX_N || passes_raw < 1 || passes_raw > (long)MAX_PASSES) return -1;
    usz n = (usz)n_raw;
    if (length != 2 + 2 * n) return -1;

    long[MAX_N] a, b;
    for (usz i = 0; i < n; i += 1) {
        a[i] = input[2 + i];
        b[i] = input[2 + n + i];
        if (!bounded_value(a[i]) || !bounded_value(b[i])) return -1;
    }
    if (output == null || output_capacity < 8 * n) return -2;

    for (long pass = 0; pass < passes_raw; pass += 1)
        for (usz i = 0; i + 1 < n; i += 1)
            a[i] = a[i + 1] + b[i];
    for (usz i = 0; i < n; i += 1) store_i64_le(output, 8 * i, a[i]);
    return (long)n;
}
