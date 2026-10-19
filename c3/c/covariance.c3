module covariance;

const usz MAX_DIMENSION = 64;
const usz MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION;
const double INVALID_RESULT = -1e300;

double covariance(long* values, ulong length) @export("covariance") {
    if (values == null || length != 2 || values[0] < 2 || values[0] > (long)MAX_DIMENSION ||
        values[1] < 1 || values[1] > (long)MAX_DIMENSION) return INVALID_RESULT;
    usz n = (usz)values[0], m = (usz)values[1];
    double float_n = (double)n;
    double[MAX_CELLS] data = {};
    double[MAX_CELLS] cov = {};
    double[MAX_DIMENSION] mean = {};
    for (usz i = 0; i < n; i++)
        for (usz j = 0; j < m; j++) data[i * m + j] = ((double)i * (double)j) / (double)m;
    for (usz j = 0; j < m; j++) {
        mean[j] = 0.0;
        for (usz i = 0; i < n; i++) mean[j] += data[i * m + j];
        mean[j] /= float_n;
    }
    for (usz i = 0; i < n; i++)
        for (usz j = 0; j < m; j++) data[i * m + j] -= mean[j];
    for (usz i = 0; i < m; i++) {
        for (usz j = i; j < m; j++) {
            cov[i * m + j] = 0.0;
            for (usz k = 0; k < n; k++) cov[i * m + j] += data[k * m + i] * data[k * m + j];
            cov[i * m + j] /= float_n - 1.0;
            cov[j * m + i] = cov[i * m + j];
        }
    }
    double checksum = 0.0;
    for (usz i = 0; i < m; i++)
        for (usz j = 0; j < m; j++) checksum += cov[i * m + j];
    return checksum;
}
