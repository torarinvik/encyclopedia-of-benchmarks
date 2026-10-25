// Clean-room bounded port of TSVC s253; see package README for provenance.
module tsvc_s253_conditional_affine_update;

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 2 + 4 * MAX_N;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

long tsvc_s253_conditional_affine_update(long* input, usz length,
        char* output, usz output_capacity) @export("tsvc_s253_conditional_affine_update") {
    if (input == null || length < 6 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0], passes_raw = input[1];
    if (n_raw < 1 || n_raw > (long)MAX_N || passes_raw < 1 || passes_raw > 8) return -1;
    usz n = (usz)n_raw, passes = (usz)passes_raw;
    if (length != 2 + 4 * n) return -1;
    for (usz i = 2; i < length; i++) if (input[i] < -2 || input[i] > 2) return -1;
    if (output == null || output_capacity < 16 * n) return -2;

    usz a_start = 2, b_start = a_start + n, c_start = b_start + n, d_start = c_start + n;
    long[MAX_N] a = zeroed;
    long[MAX_N] c = zeroed;
    for (usz i = 0; i < n; i++) {
        a[i] = input[a_start + i];
        c[i] = input[c_start + i];
    }
    for (usz pass = 0; pass < passes; pass++) {
        for (usz i = 0; i < n; i++) {
            long b_value = input[b_start + i];
            if (a[i] > b_value) {
                long value = a[i] - b_value * input[d_start + i];
                c[i] += value;
                a[i] = value;
            }
        }
    }
    for (usz i = 0; i < n; i++) {
        store_i64_le(output, 8 * i, a[i]);
        store_i64_le(output, 8 * (n + i), c[i]);
    }
    return (long)(2 * n);
}
