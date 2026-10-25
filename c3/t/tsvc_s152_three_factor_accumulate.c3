module tsvc_s152_three_factor_accumulate;

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 2 + 4 * MAX_N;
const long MAX_VALUE = 2;
const usz MAX_PASSES = 32;

fn bool bounded_value(long value) {
    return value >= -MAX_VALUE && value <= MAX_VALUE;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tsvc_s152_three_factor_accumulate(long* input, usz length, char* output,
        usz output_capacity) @export("tsvc_s152_three_factor_accumulate") {
    if (input == null || length < 6 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0], passes_raw = input[1];
    if (n_raw < 1 || n_raw > (long)MAX_N || passes_raw < 1 || passes_raw > (long)MAX_PASSES) return -1;
    usz n = (usz)n_raw;
    if (length != 2 + 4 * n) return -1;

    usz a_start = 2, c_start = a_start + n, d_start = c_start + n, e_start = d_start + n;
    long[MAX_N] a;
    for (usz i = 0; i < n; i += 1) {
        a[i] = input[a_start + i];
        if (!bounded_value(a[i]) || !bounded_value(input[c_start + i]) ||
            !bounded_value(input[d_start + i]) || !bounded_value(input[e_start + i])) return -1;
    }
    if (output == null || output_capacity < 8 * n) return -2;

    for (long pass = 0; pass < passes_raw; pass += 1) {
        for (usz i = 0; i < n; i += 1) {
            long temporary = input[d_start + i] * input[e_start + i];
            a[i] += temporary * input[c_start + i];
        }
    }
    for (usz i = 0; i < n; i += 1) store_i64_le(output, 8 * i, a[i]);
    return (long)n;
}
