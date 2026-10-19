module jacobi_1d;

const MAX_N = 30;
const MAX_TSTEPS = 20;
extern fn double trunc(double value);

fn long jacobi_1d(double* input, usz length, double* output, usz capacity)
    @export("jacobi_1d") {
    if (input == null || length != 2 || trunc(input[0]) != input[0] ||
        trunc(input[1]) != input[1] || input[0] < 1.0 || input[0] > MAX_N ||
        input[1] < 0.0 || input[1] > MAX_TSTEPS) return -1;
    usz n = (usz)input[0];
    usz tsteps = (usz)input[1];
    if (output == null || capacity < n) return -2;

    double[MAX_N] a, b;
    for (usz i = 0; i < n; i++) {
        a[i] = ((double)i + 2.0) / (double)n;
        b[i] = ((double)i + 3.0) / (double)n;
    }
    for (usz t = 0; t < tsteps; t++) {
        if (n > 2) {
            for (usz i = 1; i + 1 < n; i++) b[i] = 0.33333 * (a[i - 1] + a[i] + a[i + 1]);
            for (usz i = 1; i + 1 < n; i++) a[i] = 0.33333 * (b[i - 1] + b[i] + b[i + 1]);
        }
    }
    for (usz i = 0; i < n; i++) output[i] = a[i];
    return (long)n;
}
