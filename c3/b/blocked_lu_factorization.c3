module blocked_lu_factorization;

const usz MAX_N = 8;
const usz MAX_INPUT_LENGTH = 66;
const usz MAX_OUTPUT_ELEMENTS = 128;

fn bool finite_value(double x) { return x == x && x >= -1e308 && x <= 1e308; }
fn bool exact_integer(double x, long lo, long hi, long* out) {
    if (!finite_value(x) || x < (double)lo || x > (double)hi) return false;
    long v = (long)x;
    if ((double)v != x) return false;
    *out = v;
    return true;
}
fn double rounded_mul(double a, double b) @noinline { return a * b; }
fn double rounded_add(double a, double b) @noinline { return a + b; }
fn double rounded_sub(double a, double b) @noinline { return a - b; }
fn double rounded_div(double a, double b) @noinline { return a / b; }

fn long blocked_lu_factorization(double* input, usz input_length, double* output, usz output_capacity)
    @export("blocked_lu_factorization") {
    if (input == null || input_length < 1 || input_length > MAX_INPUT_LENGTH) return -1L;
    long nv;
    if (!exact_integer(input[0], 2, (long)MAX_N, &nv)) return -1L;
    usz n = (usz)nv;
    if ((n & 1) != 0 || input_length != 1 + n * n) return -1L;
    double[MAX_N * MAX_N] schur = zeroed;
    for (usz row = 0; row < n; row++) {
        long off_sum = 0;
        for (usz col = 0; col < n; col++) {
            usz p = row * n + col;
            long value;
            if (!exact_integer(input[p + 1], row == col ? 1 : -2, row == col ? 16 : 2, &value)) return -1L;
            schur[p] = (double)value;
            if (row != col) off_sum += value < 0 ? -value : value;
        }
        if (schur[row * n + row] <= (double)off_sum) return -1L;
    }
    double[MAX_N * MAX_N] lower = zeroed;
    double[MAX_N * MAX_N] upper = zeroed;
    for (usz k = 0; k < n; k += 2) {
        double u00 = schur[k * n + k];
        double u01 = schur[k * n + k + 1];
        if (!finite_value(u00) || u00 == 0.0) return -1L;
        double l10 = rounded_div(schur[(k + 1) * n + k], u00);
        double u11 = rounded_sub(schur[(k + 1) * n + k + 1], rounded_mul(l10, u01));
        if (!finite_value(l10) || !finite_value(u11) || u11 == 0.0) return -1L;
        lower[k * n + k] = 1.0;
        lower[(k + 1) * n + k] = l10;
        lower[(k + 1) * n + k + 1] = 1.0;
        upper[k * n + k] = u00;
        upper[k * n + k + 1] = u01;
        upper[(k + 1) * n + k + 1] = u11;
        for (usz j = k + 2; j < n; j += 2) {
            for (usz col = j; col < j + 2; col++) {
                double s0 = schur[k * n + col];
                double s1 = schur[(k + 1) * n + col];
                upper[k * n + col] = s0;
                upper[(k + 1) * n + col] = rounded_sub(s1, rounded_mul(l10, s0));
            }
        }
        for (usz i = k + 2; i < n; i += 2) {
            for (usz row = i; row < i + 2; row++) {
                double s0 = schur[row * n + k];
                double s1 = schur[row * n + k + 1];
                double l0 = rounded_div(s0, u00);
                double l1 = rounded_div(rounded_sub(s1, rounded_mul(l0, u01)), u11);
                lower[row * n + k] = l0;
                lower[row * n + k + 1] = l1;
            }
        }
        for (usz i = k + 2; i < n; i += 2) {
            for (usz j = k + 2; j < n; j += 2) {
                for (usz row = i; row < i + 2; row++) {
                    for (usz col = j; col < j + 2; col++) {
                        double update = rounded_mul(lower[row * n + k], upper[k * n + col]);
                        update = rounded_add(update, rounded_mul(lower[row * n + k + 1], upper[(k + 1) * n + col]));
                        schur[row * n + col] = rounded_sub(schur[row * n + col], update);
                    }
                }
            }
        }
    }
    double[MAX_OUTPUT_ELEMENTS] staged = zeroed;
    usz m = n * n;
    for (usz row = 0; row < n; row++) {
        for (usz col = 0; col < n; col++) {
            if (row == col) lower[row * n + col] = 1.0;
            if (row <= col) upper[row * n + col] = schur[row * n + col];
        }
    }
    for (usz i = 0; i < m; i++) {
        if (!finite_value(lower[i]) || !finite_value(upper[i])) return -1L;
        staged[i] = lower[i];
        staged[m + i] = upper[i];
    }
    usz output_length = 2 * m;
    if (output == null || output_capacity < output_length) return -2L;
    for (usz i = 0; i < output_length; i++) output[i] = staged[i];
    return (long)output_length;
}
