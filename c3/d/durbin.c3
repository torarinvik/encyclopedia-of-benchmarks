module durbin;

const MAX_N = 40;
extern fn double trunc(double value);

fn long durbin(double* input, usz length, double* output, usz capacity)
    @export("durbin") {
    if (input == null || length != 1 || trunc(input[0]) != input[0] ||
        input[0] < 1.0 || input[0] > MAX_N) return -1;
    usz n = (usz)input[0];
    if (output == null || capacity < n) return -2;

    double[MAX_N] r, y, z;
    for (usz i = 0; i < n; i++) r[i] = (double)(n + 1 - i);
    y[0] = -r[0];
    double beta = 1.0;
    double alpha = -r[0];
    for (usz k = 1; k < n; k++) {
        beta = (1.0 - alpha * alpha) * beta;
        double sum = 0.0;
        for (usz i = 0; i < k; i++) sum += r[k - i - 1] * y[i];
        alpha = -(r[k] + sum) / beta;
        for (usz i = 0; i < k; i++) z[i] = y[i] + alpha * y[k - i - 1];
        for (usz i = 0; i < k; i++) y[i] = z[i];
        y[k] = alpha;
    }
    for (usz i = 0; i < n; i++) output[i] = y[i];
    return (long)n;
}
