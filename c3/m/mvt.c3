module mvt;

const usz MAX_DIMENSION = 64;
const usz MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION;
const double INVALID_RESULT = -1e300;

double mvt(long* values, ulong length) @export("mvt") {
    if (values == null || length != 1 || values[0] < 1 || values[0] > (long)MAX_DIMENSION)
        return INVALID_RESULT;
    usz n = (usz)values[0];
    double[MAX_DIMENSION] x1 = {};
    double[MAX_DIMENSION] x2 = {};
    double[MAX_DIMENSION] y1 = {};
    double[MAX_DIMENSION] y2 = {};
    double[MAX_CELLS] matrix = {};
    for (usz i = 0; i < n; i++) {
        x1[i] = (double)(i % n) / (double)n;
        x2[i] = (double)((i + 1) % n) / (double)n;
        y1[i] = (double)((i + 3) % n) / (double)n;
        y2[i] = (double)((i + 4) % n) / (double)n;
        for (usz j = 0; j < n; j++) matrix[i * n + j] = (double)((i * j) % n) / (double)n;
    }
    for (usz i = 0; i < n; i++)
        for (usz j = 0; j < n; j++)
            x1[i] = x1[i] + matrix[i * n + j] * y1[j];
    for (usz i = 0; i < n; i++)
        for (usz j = 0; j < n; j++)
            x2[i] = x2[i] + matrix[j * n + i] * y2[j];
    double checksum = 0.0;
    for (usz i = 0; i < n; i++) checksum += x1[i];
    for (usz i = 0; i < n; i++) checksum += x2[i];
    return checksum;
}
