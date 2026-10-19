module polybench_symm;

const usz MAX_DIMENSION = 64;
const usz MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION;
const double INVALID_RESULT = -1e300;

fn double polybench_symm(long* values, ulong length) @export("polybench_symm") {
    if (values == null || length != 2 || values[0] < 1 || values[0] > (long)MAX_DIMENSION ||
        values[1] < 1 || values[1] > (long)MAX_DIMENSION) return INVALID_RESULT;
    usz m = (usz)values[0], n = (usz)values[1];
    double[MAX_CELLS] a = {};
    double[MAX_CELLS] b = {};
    double[MAX_CELLS] c = {};
    double alpha = 1.5, beta = 1.2;
    for (usz i = 0; i < m; i++)
        for (usz j = 0; j < n; j++) {
            c[i * n + j] = (double)((i + j) % 100) / (double)m;
            b[i * n + j] = (double)((n + i - j) % 100) / (double)m;
        }
    for (usz i = 0; i < m; i++)
        for (usz j = 0; j < m; j++)
            a[i * m + j] = j <= i ? (double)((i + j) % 100) / (double)m : -999.0;
    for (usz i = 0; i < m; i++)
        for (usz j = 0; j < n; j++) {
            double temp2 = 0.0;
            for (usz k = 0; k < i; k++) {
                c[k * n + j] = c[k * n + j] + alpha * b[i * n + j] * a[i * m + k];
                temp2 = temp2 + b[k * n + j] * a[i * m + k];
            }
            c[i * n + j] = beta * c[i * n + j] + alpha * b[i * n + j] * a[i * m + i] + alpha * temp2;
        }
    double result = 0.0;
    for (usz i = 0; i < m; i++)
        for (usz j = 0; j < n; j++) result += c[i * n + j];
    return result;
}
