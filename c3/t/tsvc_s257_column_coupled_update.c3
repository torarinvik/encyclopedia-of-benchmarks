module tsvc_s257_column_coupled_update;

const MAX_N = 8;
const MAX_PASSES = 4;

fn long tsvc_s257_column_coupled_update(long* values, usz length)
    @export("tsvc_s257_column_coupled_update") {
    if (values == null || length < 12 || length > 2 + MAX_N + 2 * MAX_N * MAX_N) return -1;
    long n_value = values[0];
    long passes_value = values[1];
    if (n_value < 2 || n_value > MAX_N || passes_value < 1 || passes_value > MAX_PASSES) return -1;
    usz n = (usz)n_value;
    usz passes = (usz)passes_value;
    if (length != 2 + n + 2 * n * n) return -1;
    for (usz index = 2; index < length; index++) {
        if (values[index] < -1 || values[index] > 1) return -1;
    }

    long[MAX_N] a;
    long[MAX_N * MAX_N] aa, bb;
    for (usz i = 0; i < n; i++) a[i] = values[2 + i];
    usz aa_start = 2 + n;
    usz bb_start = aa_start + n * n;
    for (usz i = 0; i < n * n; i++) {
        aa[i] = values[aa_start + i];
        bb[i] = values[bb_start + i];
    }
    for (usz pass = 0; pass < passes; pass++) {
        for (usz i = 1; i < n; i++) {
            for (usz j = 0; j < n; j++) {
                usz cell = j * n + i;
                a[i] = aa[cell] - a[i - 1];
                aa[cell] = a[i] + bb[cell];
            }
        }
    }
    long checksum = 0;
    for (usz i = 0; i < n; i++) checksum += a[i];
    for (usz i = 0; i < n * n; i++) checksum += aa[i];
    return checksum;
}
