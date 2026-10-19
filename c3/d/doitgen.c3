module doitgen;

const usz MAX_DIMENSION = 16;
const usz MAX_A_CELLS = MAX_DIMENSION * MAX_DIMENSION * MAX_DIMENSION;
const usz MAX_C4_CELLS = MAX_DIMENSION * MAX_DIMENSION;
const double INVALID_RESULT = -1e300;

double doitgen(long* values, ulong length) @export("doitgen") {
    if (values == null || length != 3 || values[0] < 1 || values[0] > (long)MAX_DIMENSION ||
        values[1] < 1 || values[1] > (long)MAX_DIMENSION || values[2] < 1 || values[2] > (long)MAX_DIMENSION)
        return INVALID_RESULT;
    usz nr = (usz)values[0], nq = (usz)values[1], np = (usz)values[2];
    double[MAX_A_CELLS] a = {};
    double[MAX_C4_CELLS] c4 = {};
    double[MAX_DIMENSION] sum = {};
    for (usz r = 0; r < nr; r++)
        for (usz q = 0; q < nq; q++)
            for (usz p = 0; p < np; p++) a[(r * nq + q) * np + p] = (double)((r * q + p) % np) / (double)np;
    for (usz i = 0; i < np; i++)
        for (usz j = 0; j < np; j++) c4[i * np + j] = (double)(i * j % np) / (double)np;
    for (usz r = 0; r < nr; r++) {
        for (usz q = 0; q < nq; q++) {
            for (usz p = 0; p < np; p++) {
                sum[p] = 0.0;
                for (usz s = 0; s < np; s++) sum[p] += a[(r * nq + q) * np + s] * c4[s * np + p];
            }
            for (usz p = 0; p < np; p++) a[(r * nq + q) * np + p] = sum[p];
        }
    }
    double checksum = 0.0;
    for (usz r = 0; r < nr; r++)
        for (usz q = 0; q < nq; q++)
            for (usz p = 0; p < np; p++) checksum += a[(r * nq + q) * np + p];
    return checksum;
}
