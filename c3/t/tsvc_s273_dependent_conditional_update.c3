module tsvc_s273_dependent_conditional_update;

const MAX_N = 64;
const MAX_PASSES = 8;

fn long tsvc_s273_dependent_conditional_update(long* values, usz length)
    @export("tsvc_s273_dependent_conditional_update") {
    if (values == null || length < 7 || length > 2 + 5 * MAX_N) return -1;
    long n_value = values[0];
    long passes_value = values[1];
    if (n_value < 1 || n_value > MAX_N || passes_value < 1 || passes_value > MAX_PASSES) return -1;
    usz n = (usz)n_value;
    usz passes = (usz)passes_value;
    if (length != 2 + 5 * n) return -1;
    for (usz index = 2; index < length; index++) {
        if (values[index] < -2 || values[index] > 2) return -1;
    }

    long[MAX_N] a, b, c, d, e;
    for (usz i = 0; i < n; i++) {
        a[i] = values[2 + i];
        b[i] = values[2 + n + i];
        c[i] = values[2 + 2 * n + i];
        d[i] = values[2 + 3 * n + i];
        e[i] = values[2 + 4 * n + i];
    }
    for (usz pass = 0; pass < passes; pass++) {
        for (usz i = 0; i < n; i++) {
            a[i] += d[i] * e[i];
            if (a[i] < 0) b[i] += d[i] * e[i];
            c[i] += a[i] * d[i];
        }
    }
    long checksum = 0;
    for (usz i = 0; i < n; i++) checksum += a[i] + b[i] + c[i];
    return checksum;
}
