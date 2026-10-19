module atax;

const usz MAX_DIMENSION = 64;
const usz MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION;
const double INVALID_RESULT = -1e300;

double atax(long* values, ulong length) @export("atax") {
    if (values == null || length != 2 || values[0] < 1 || values[0] > (long)MAX_DIMENSION ||
        values[1] < 1 || values[1] > (long)MAX_DIMENSION) return INVALID_RESULT;
    usz m = (usz)values[0], n = (usz)values[1];
    double[MAX_CELLS] matrix = {};
    double[MAX_DIMENSION] x = {};
    double[MAX_DIMENSION] y = {};
    double[MAX_DIMENSION] temporary = {};
    double fn = (double)n;
    for (usz i = 0; i < n; i++) x[i] = 1.0 + (double)i / fn;
    for (usz i = 0; i < m; i++)
        for (usz j = 0; j < n; j++)
            matrix[i * n + j] = (double)((i + j) % n) / (double)(5 * m);
    for (usz i = 0; i < n; i++) y[i] = 0.0;
    for (usz i = 0; i < m; i++) {
        temporary[i] = 0.0;
        for (usz j = 0; j < n; j++)
            temporary[i] = temporary[i] + matrix[i * n + j] * x[j];
        for (usz j = 0; j < n; j++)
            y[j] = y[j] + matrix[i * n + j] * temporary[i];
    }
    double checksum = 0.0;
    for (usz j = 0; j < n; j++) checksum += y[j];
    return checksum;
}
