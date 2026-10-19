module polybench_cholesky;

extern fn double sqrt(double value);

const usz MAX_DIMENSION = 64;
const usz MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION;
const double INVALID_RESULT = -1e300;

fn double polybench_cholesky(long* values, ulong length) @export("polybench_cholesky") {
    if (values == null || length != 1 || values[0] < 1 || values[0] > (long)MAX_DIMENSION)
        return INVALID_RESULT;
    usz n = (usz)values[0];
    double[MAX_CELLS] a = {};
    double[MAX_CELLS] product = {};
    for (usz i = 0; i < n; i++) {
        for (usz j = 0; j <= i; j++) a[i * n + j] = (double)(-(long)j % (long)n) / (double)n + 1.0;
        for (usz j = i + 1; j < n; j++) a[i * n + j] = 0.0;
        a[i * n + i] = 1.0;
    }
    for (usz r = 0; r < n; r++)
        for (usz s = 0; s < n; s++) product[r * n + s] = 0.0;
    for (usz t = 0; t < n; t++)
        for (usz r = 0; r < n; r++)
            for (usz s = 0; s < n; s++)
                product[r * n + s] = product[r * n + s] + a[r * n + t] * a[s * n + t];
    for (usz r = 0; r < n; r++)
        for (usz s = 0; s < n; s++) a[r * n + s] = product[r * n + s];

    for (usz i = 0; i < n; i++) {
        for (usz j = 0; j < i; j++) {
            for (usz k = 0; k < j; k++) a[i * n + j] = a[i * n + j] - a[i * n + k] * a[j * n + k];
            a[i * n + j] = a[i * n + j] / a[j * n + j];
        }
        for (usz k = 0; k < i; k++) a[i * n + i] = a[i * n + i] - a[i * n + k] * a[i * n + k];
        a[i * n + i] = sqrt(a[i * n + i]);
    }
    double result = 0.0;
    for (usz i = 0; i < n; i++)
        for (usz j = 0; j <= i; j++) result += a[i * n + j];
    return result;
}
