module two_mm;

const usz MAX_DIMENSION = 16;
const usz MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION;
const double INVALID_RESULT = -1e300;

double two_mm(long* values, ulong length) @export("two_mm") {
    if (values == null || length != 4) return INVALID_RESULT;
    for (usz i = 0; i < 4; i++)
        if (values[i] < 1 || values[i] > (long)MAX_DIMENSION) return INVALID_RESULT;
    usz ni = (usz)values[0], nj = (usz)values[1], nk = (usz)values[2], nl = (usz)values[3];
    const double alpha = 1.5, beta = 1.2;
    double[MAX_CELLS] a = {};
    double[MAX_CELLS] b = {};
    double[MAX_CELLS] c = {};
    double[MAX_CELLS] d = {};
    double[MAX_CELLS] tmp = {};
    for (usz i = 0; i < ni; i++)
        for (usz k = 0; k < nk; k++) a[i * nk + k] = (double)((i * k + 1) % ni) / (double)ni;
    for (usz k = 0; k < nk; k++)
        for (usz j = 0; j < nj; j++) b[k * nj + j] = (double)(k * (j + 1) % nj) / (double)nj;
    for (usz j = 0; j < nj; j++)
        for (usz l = 0; l < nl; l++) c[j * nl + l] = (double)((j * (l + 3) + 1) % nl) / (double)nl;
    for (usz i = 0; i < ni; i++)
        for (usz l = 0; l < nl; l++) d[i * nl + l] = (double)(i * (l + 2) % nk) / (double)nk;
    for (usz i = 0; i < ni; i++)
        for (usz j = 0; j < nj; j++) {
            tmp[i * nj + j] = 0.0;
            for (usz k = 0; k < nk; k++) tmp[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j];
        }
    for (usz i = 0; i < ni; i++)
        for (usz l = 0; l < nl; l++) {
            d[i * nl + l] *= beta;
            for (usz j = 0; j < nj; j++) d[i * nl + l] += tmp[i * nj + j] * c[j * nl + l];
        }
    double checksum = 0.0;
    for (usz i = 0; i < ni; i++)
        for (usz l = 0; l < nl; l++) checksum += d[i * nl + l];
    return checksum;
}
