// Clean-room port of TSVC s258; see package README for provenance and rights.
module tsvc_s258_wrapped_scalar_expansion;

const usz MAX_N = 64;

long tsvc_s258_wrapped_scalar_expansion(long* input, usz length)
        @export("tsvc_s258_wrapped_scalar_expansion") {
    if (input == null || length < 5 || length > 257) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != 1 + 4 * n) return -1;
    long[MAX_N] a, c, d, aa0, b, e;
    usz c_start = 1 + n;
    usz d_start = 1 + 2 * n;
    usz aa_start = 1 + 3 * n;
    for (usz i = 0; i < n; i++) {
        a[i] = input[1 + i];
        c[i] = input[c_start + i];
        d[i] = input[d_start + i];
        aa0[i] = input[aa_start + i];
        if (a[i] < 0 || a[i] > 2 || c[i] < 0 || c[i] > 2 ||
            d[i] < 0 || d[i] > 2 || aa0[i] < 0 || aa0[i] > 2) return -1;
    }
    long s = 0;
    for (usz i = 0; i < n; i++) {
        if (a[i] > 0) s = d[i] * d[i];
        b[i] = s * c[i] + d[i];
        e[i] = (s + 1) * aa0[i];
    }
    long sum_b = 0, sum_e = 0;
    for (usz i = 0; i < n; i++) sum_b += b[i];
    for (usz i = 0; i < n; i++) sum_e += e[i];
    return sum_b + sum_e;
}
