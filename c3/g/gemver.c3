module gemver;

const usz MAX_DIMENSION = 64;
const usz MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION;
const double INVALID_RESULT = -1e300;

double gemver(long* values, ulong length) @export("gemver") {
    if (values == null || length != 1 || values[0] < 1 || values[0] > (long)MAX_DIMENSION)
        return INVALID_RESULT;
    usz n = (usz)values[0];
    const double alpha = 1.5, beta = 1.2;
    double[MAX_CELLS] a = {};
    double[MAX_DIMENSION] u1 = {}, v1 = {}, u2 = {}, v2 = {};
    double[MAX_DIMENSION] w = {}, x = {}, y = {}, z = {};
    for (usz i = 0; i < n; i++) {
        u1[i] = (double)i;
        u2[i] = (((double)i + 1.0) / (double)n) / 2.0;
        v1[i] = (((double)i + 1.0) / (double)n) / 4.0;
        v2[i] = (((double)i + 1.0) / (double)n) / 6.0;
        y[i] = (((double)i + 1.0) / (double)n) / 8.0;
        z[i] = (((double)i + 1.0) / (double)n) / 9.0;
        for (usz j = 0; j < n; j++) a[i * n + j] = (double)((i * j) % n) / (double)n;
    }
    for (usz i = 0; i < n; i++)
        for (usz j = 0; j < n; j++) a[i * n + j] = a[i * n + j] + u1[i] * v1[j] + u2[i] * v2[j];
    for (usz i = 0; i < n; i++)
        for (usz j = 0; j < n; j++) x[i] = x[i] + beta * a[j * n + i] * y[j];
    for (usz i = 0; i < n; i++) x[i] = x[i] + z[i];
    for (usz i = 0; i < n; i++)
        for (usz j = 0; j < n; j++) w[i] = w[i] + alpha * a[i * n + j] * x[j];
    double checksum = 0.0;
    for (usz i = 0; i < n; i++) checksum += w[i];
    return checksum;
}
