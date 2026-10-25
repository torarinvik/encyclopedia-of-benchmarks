// Clean-room bounded port of TSVC s251; see package README for provenance.
module tsvc_s251_scalar_square_expansion;

const usz MAX_N = 64;
const usz MAX_PASSES = 8;
const usz MAX_INPUT_LENGTH = 2 + 3 * MAX_N;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

long tsvc_s251_scalar_square_expansion(long* input, usz length,
        char* output, usz output_capacity) @export("tsvc_s251_scalar_square_expansion") {
    if (input == null || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0], passes_raw = input[1];
    if (n_raw < 1 || n_raw > (long)MAX_N || passes_raw < 1 || passes_raw > (long)MAX_PASSES) return -1;
    usz n = (usz)n_raw, passes = (usz)passes_raw;
    if (length != 2 + 3 * n) return -1;
    for (usz i = 2; i < length; i++) if (input[i] < -2 || input[i] > 2) return -1;
    if (output == null || output_capacity < 8 * n) return -2;

    usz b_start = 2, c_start = b_start + n, d_start = c_start + n;
    long[MAX_N] a = zeroed;
    for (usz pass = 0; pass < passes; pass++) {
        for (usz i = 0; i < n; i++) {
            long scalar = input[b_start + i] + input[c_start + i] * input[d_start + i];
            a[i] = scalar * scalar;
        }
    }
    for (usz i = 0; i < n; i++) store_i64_le(output, 8 * i, a[i]);
    return (long)n;
}
