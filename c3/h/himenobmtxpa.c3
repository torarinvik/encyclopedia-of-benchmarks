module himenobmtxpa;
extern fn double trunc(double value);

const long MAX_SIDE = 6;
const usz MAX_CELLS = 216;

fn long himenobmtxpa(double* input, usz length, double* output, usz capacity)
    @export("himenobmtxpa") {
    if (input == null || length != 4) return -1;
    for (usz q = 0; q < 4; q++)
        if (input[q] != input[q] || trunc(input[q]) != input[q]) return -1;
    if (input[0] < 2 || input[0] > MAX_SIDE || input[1] < 2 || input[1] > MAX_SIDE ||
        input[2] < 2 || input[2] > MAX_SIDE || input[3] < 1 || input[3] > 4) return -1;
    usz nx = (usz)input[0], ny = (usz)input[1], nz = (usz)input[2];
    usz iterations = (usz)input[3];
    if (output == null || capacity < 1) return -2;

    float[MAX_CELLS] p;
    float[MAX_CELLS] work;
    float a3 = 1.0 / 6.0, omega = 0.8;
    float denominator = (float)((nx - 1) * (nx - 1));
    for (usz i = 0; i < nx; i++) for (usz j = 0; j < ny; j++) for (usz k = 0; k < nz; k++) {
        usz q = i * ny * nz + j * nz + k;
        p[q] = (float)(i * i) / denominator;
    }
    float gosa = 0.0;
    for (usz iteration = 0; iteration < iterations; iteration++) {
        gosa = 0.0;
        for (usz i = 1; i + 1 < nx; i++) for (usz j = 1; j + 1 < ny; j++) for (usz k = 1; k + 1 < nz; k++) {
            usz q = i * ny * nz + j * nz + k;
            float s0 = p[q + ny * nz] + p[q + nz] + p[q + 1];
            s0 = s0 + p[q - ny * nz] + p[q - nz] + p[q - 1];
            float ss = s0 * a3 - p[q];
            gosa = gosa + ss * ss;
            work[q] = p[q] + omega * ss;
        }
        for (usz i = 1; i + 1 < nx; i++) for (usz j = 1; j + 1 < ny; j++) for (usz k = 1; k + 1 < nz; k++) {
            usz q = i * ny * nz + j * nz + k;
            p[q] = work[q];
        }
    }
    output[0] = (double)gosa;
    return 1;
}
