module jacobi_2d;

const MAX_N = 30;
const MAX_TSTEPS = 20;
extern fn double trunc(double value);

fn long jacobi_2d(double* input, usz length, double* output, usz capacity)
    @export("jacobi_2d") {
    if (input == null || length != 2 || trunc(input[0]) != input[0] ||
        trunc(input[1]) != input[1] || input[0] < 1.0 || input[0] > MAX_N ||
        input[1] < 0.0 || input[1] > MAX_TSTEPS) return -1;
    usz n = (usz)input[0];
    usz tsteps = (usz)input[1];
    usz count = n * n;
    if (output == null || capacity < count) return -2;

    double[MAX_N][MAX_N] a, b;
    for (usz i = 0; i < n; i++) {
        for (usz j = 0; j < n; j++) {
            a[i][j] = ((double)i * (double)(j + 2) + 2.0) / (double)n;
            b[i][j] = ((double)i * (double)(j + 3) + 3.0) / (double)n;
        }
    }
    for (usz t = 0; t < tsteps; t++) {
        if (n > 2) {
            for (usz i = 1; i + 1 < n; i++) {
                for (usz j = 1; j + 1 < n; j++)
                    b[i][j] = 0.2 * (a[i][j] + a[i][j - 1] + a[i][j + 1] + a[i + 1][j] + a[i - 1][j]);
            }
            for (usz i = 1; i + 1 < n; i++) {
                for (usz j = 1; j + 1 < n; j++)
                    a[i][j] = 0.2 * (b[i][j] + b[i][j - 1] + b[i][j + 1] + b[i + 1][j] + b[i - 1][j]);
            }
        }
    }
    for (usz i = 0; i < n; i++)
        for (usz j = 0; j < n; j++) output[i * n + j] = a[i][j];
    return (long)count;
}
