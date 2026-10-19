module gemm;

const usz MAX_DIMENSION = 64;
const usz MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION;
const double INVALID_RESULT = -1e300;

double gemm(long* values, ulong length) @export("gemm") {
    if (values == null || length != 3 || values[0] < 1 || values[0] > (long)MAX_DIMENSION ||
        values[1] < 1 || values[1] > (long)MAX_DIMENSION || values[2] < 1 || values[2] > (long)MAX_DIMENSION)
        return INVALID_RESULT;
    usz ni = (usz)values[0], nj = (usz)values[1], nk = (usz)values[2];
    const double alpha = 1.5, beta = 1.2;
    double[MAX_CELLS] c = {};
    double[MAX_CELLS] a = {};
    double[MAX_CELLS] b = {};
    for (usz i = 0; i < ni; i++)
        for (usz j = 0; j < nj; j++) c[i * nj + j] = (double)((i * j + 1) % ni) / (double)ni;
    for (usz i = 0; i < ni; i++)
        for (usz k = 0; k < nk; k++) a[i * nk + k] = (double)(i * (k + 1) % nk) / (double)nk;
    for (usz k = 0; k < nk; k++)
        for (usz j = 0; j < nj; j++) b[k * nj + j] = (double)(k * (j + 2) % nj) / (double)nj;
    for (usz i = 0; i < ni; i++) {
        for (usz j = 0; j < nj; j++) c[i * nj + j] *= beta;
        for (usz k = 0; k < nk; k++)
            for (usz j = 0; j < nj; j++) c[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j];
    }
    double checksum = 0.0;
    for (usz i = 0; i < ni; i++)
        for (usz j = 0; j < nj; j++) checksum += c[i * nj + j];
    return checksum;
}
