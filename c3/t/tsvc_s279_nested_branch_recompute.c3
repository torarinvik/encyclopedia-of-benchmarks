// Clean-room bounded port of TSVC s279; see package README for provenance.
module tsvc_s279_nested_branch_recompute;

const usz MAX_N = 64;
const usz MAX_PASSES = 8;
const usz MAX_INPUT_LENGTH = 2 + 5 * MAX_N;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

long tsvc_s279_nested_branch_recompute(long* input, usz length,
        char* output, usz output_capacity) @export("tsvc_s279_nested_branch_recompute") {
    if (input == null || length < 7 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0], passes_raw = input[1];
    if (n_raw < 1 || n_raw > (long)MAX_N || passes_raw < 1 || passes_raw > (long)MAX_PASSES) return -1;
    usz n = (usz)n_raw, passes = (usz)passes_raw;
    if (length != 2 + 5 * n) return -1;
    for (usz i = 2; i < length; i++) if (input[i] < -2 || input[i] > 2) return -1;
    if (output == null || output_capacity < 24 * n) return -2;

    usz a_start = 2, b_start = a_start + n, c_start = b_start + n;
    usz d_start = c_start + n, e_start = d_start + n;
    long[MAX_N] a = zeroed;
    long[MAX_N] b = zeroed;
    long[MAX_N] c = zeroed;
    for (usz i = 0; i < n; i++) {
        a[i] = input[a_start + i];
        b[i] = input[b_start + i];
        c[i] = input[c_start + i];
    }
    for (usz pass = 0; pass < passes; pass++) {
        for (usz i = 0; i < n; i++) {
            if (a[i] > 0) {
                c[i] = -c[i] + input[e_start + i] * input[e_start + i];
            } else {
                b[i] = -b[i] + input[d_start + i] * input[d_start + i];
                if (b[i] > a[i]) c[i] += input[d_start + i] * input[e_start + i];
            }
            a[i] = b[i] + c[i] * input[d_start + i];
        }
    }
    for (usz i = 0; i < n; i++) {
        store_i64_le(output, 8 * i, a[i]);
        store_i64_le(output, 8 * (n + i), b[i]);
        store_i64_le(output, 8 * (2 * n + i), c[i]);
    }
    return (long)(3 * n);
}
