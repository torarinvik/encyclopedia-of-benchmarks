module trisolv;

const MAX_N = 40;
extern fn double trunc(double value);

fn long trisolv(double* input, usz length, double* output, usz capacity)
    @export("trisolv") {
    if (input == null || length != 1 || trunc(input[0]) != input[0] ||
        input[0] < 1.0 || input[0] > MAX_N) return -1;
    usz n = (usz)input[0];
    if (output == null || capacity < n) return -2;

    double[MAX_N][MAX_N] lower;
    double[MAX_N] b, x;
    for (usz i = 0; i < n; i++) {
        b[i] = (double)i;
        for (usz j = 0; j <= i; j++)
            lower[i][j] = (double)(i + n - j + 1) * 2.0 / (double)n;
    }
    for (usz i = 0; i < n; i++) {
        x[i] = b[i];
        for (usz j = 0; j < i; j++) x[i] -= lower[i][j] * x[j];
        x[i] /= lower[i][i];
    }
    for (usz i = 0; i < n; i++) output[i] = x[i];
    return (long)n;
}
