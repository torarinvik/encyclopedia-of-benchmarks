module bicg;

const usz MAX_DIMENSION = 64;
const usz MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION;
const double INVALID_RESULT = -1e300;

double bicg(long* values, ulong length) @export("bicg") {
    if (values == null || length != 2 || values[0] < 1 || values[0] > (long)MAX_DIMENSION ||
        values[1] < 1 || values[1] > (long)MAX_DIMENSION) return INVALID_RESULT;
    usz m = (usz)values[0], n = (usz)values[1];
    double[MAX_CELLS] matrix = {};
    double[MAX_DIMENSION] p = {};
    double[MAX_DIMENSION] r = {};
    double[MAX_DIMENSION] s = {};
    double[MAX_DIMENSION] q = {};
    for (usz i = 0; i < m; i++) p[i] = (double)(i % m) / (double)m;
    for (usz i = 0; i < n; i++) {
        r[i] = (double)(i % n) / (double)n;
        for (usz j = 0; j < m; j++) matrix[i * m + j] = (double)(i * (j + 1) % n) / (double)n;
    }
    for (usz i = 0; i < m; i++) s[i] = 0.0;
    for (usz i = 0; i < n; i++) {
        q[i] = 0.0;
        for (usz j = 0; j < m; j++) {
            s[j] = s[j] + r[i] * matrix[i * m + j];
            q[i] = q[i] + matrix[i * m + j] * p[j];
        }
    }
    double checksum = 0.0;
    for (usz j = 0; j < m; j++) checksum += s[j];
    for (usz i = 0; i < n; i++) checksum += q[i];
    return checksum;
}
