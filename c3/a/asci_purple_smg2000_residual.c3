// Clean-room bounded residual profile; see package README and RIGHTS.md.
module asci_purple_smg2000_residual;
extern fn double trunc(double value);
const long MAX_SIDE = 5;

fn long asci_purple_smg2000_residual(double* input, usz length, double* output, usz capacity) @export("asci_purple_smg2000_residual") {
    if (input == null || length < 19 || length > 253) return -1;
    for (usz q = 0; q < 3; q++) {
        double v = input[q];
        if (v != v || trunc(v) != v || v < 2 || v > MAX_SIDE) return -1;
    }
    usz nx = (usz)input[0], ny = (usz)input[1], nz = (usz)input[2];
    usz cells = nx * ny * nz;
    if (length != 3 + 2 * cells) return -1;
    for (usz q = 3; q < length; q++) {
        double v = input[q];
        if (v != v || trunc(v) != v || v < -1000 || v > 1000) return -1;
    }
    if (output == null || capacity < cells) return -2;
    usz stride_i = ny * nz, stride_j = nz;
    for (usz i = 0; i < nx; i++) for (usz j = 0; j < ny; j++) for (usz k = 0; k < nz; k++) {
        usz q = i * stride_i + j * stride_j + k;
        long x = (long)input[3 + q];
        long ax = 222 * x;
        if (i > 0) ax -= (long)input[3 + q - stride_i];
        if (i + 1 < nx) ax -= (long)input[3 + q + stride_i];
        if (j > 0) ax -= 10 * (long)input[3 + q - stride_j];
        if (j + 1 < ny) ax -= 10 * (long)input[3 + q + stride_j];
        if (k > 0) ax -= 100 * (long)input[3 + q - 1];
        if (k + 1 < nz) ax -= 100 * (long)input[3 + q + 1];
        long b = (long)input[3 + cells + q];
        output[q] = (double)(10 * b - ax) / 10.0;
    }
    return (long)cells;
}
