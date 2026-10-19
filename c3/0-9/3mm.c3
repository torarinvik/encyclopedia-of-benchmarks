module three_mm;

const usz MAX_DIMENSION = 16;
const usz MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION;
const double INVALID_RESULT = -1e300;

double three_mm(long* values, ulong length) @export("three_mm") {
    if (values == null || length != 5) return INVALID_RESULT;
    for (usz i = 0; i < 5; i++)
        if (values[i] < 1 || values[i] > (long)MAX_DIMENSION) return INVALID_RESULT;
    usz ni = (usz)values[0], nj = (usz)values[1], nk = (usz)values[2], nl = (usz)values[3], nm = (usz)values[4];
    double[MAX_CELLS] a = {};
    double[MAX_CELLS] b = {};
    double[MAX_CELLS] c = {};
    double[MAX_CELLS] d = {};
    double[MAX_CELLS] e = {};
    double[MAX_CELLS] f = {};
    double[MAX_CELLS] g = {};
    for (usz i = 0; i < ni; i++)
        for (usz k = 0; k < nk; k++) a[i * nk + k] = (double)((i * k + 1) % ni) / (double)(5 * ni);
    for (usz k = 0; k < nk; k++)
        for (usz j = 0; j < nj; j++) b[k * nj + j] = (double)((k * (j + 1) + 2) % nj) / (double)(5 * nj);
    for (usz i = 0; i < nj; i++)
        for (usz j = 0; j < nm; j++) c[i * nm + j] = (double)(i * (j + 3) % nl) / (double)(5 * nl);
    for (usz i = 0; i < nm; i++)
        for (usz j = 0; j < nl; j++) d[i * nl + j] = (double)((i * (j + 2) + 2) % nk) / (double)(5 * nk);
    for (usz i = 0; i < ni; i++)
        for (usz j = 0; j < nj; j++) {
            e[i * nj + j] = 0.0;
            for (usz k = 0; k < nk; k++) e[i * nj + j] += a[i * nk + k] * b[k * nj + j];
        }
    for (usz i = 0; i < nj; i++)
        for (usz j = 0; j < nl; j++) {
            f[i * nl + j] = 0.0;
            for (usz k = 0; k < nm; k++) f[i * nl + j] += c[i * nm + k] * d[k * nl + j];
        }
    for (usz i = 0; i < ni; i++)
        for (usz j = 0; j < nl; j++) {
            g[i * nl + j] = 0.0;
            for (usz k = 0; k < nj; k++) g[i * nl + j] += e[i * nj + k] * f[k * nl + j];
        }
    double checksum = 0.0;
    for (usz i = 0; i < ni; i++)
        for (usz j = 0; j < nl; j++) checksum += g[i * nl + j];
    return checksum;
}
