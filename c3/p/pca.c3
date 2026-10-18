module pca;

extern fn double sqrt(double value);

const usz MAX_SAMPLES = 8;
const usz MAX_OUTPUT = 12;

fn long pca(double* input, usz input_length, double* output, usz capacity) @export("pca") {
    if (input == null || input_length < 9 || input_length > 19 || input[1] != 2.0 || input[2] != 1.0) return -1L;
    if (input[0] != 3.0 && input[0] != 4.0 && input[0] != 5.0 && input[0] != 6.0 && input[0] != 7.0 && input[0] != 8.0) return -1L;
    usz n = (usz)input[0];
    if (input_length != 3 + 2 * n) return -1L;
    double[MAX_SAMPLES] x = zeroed, y = zeroed, z0 = zeroed, z1 = zeroed;
    double mean0 = 0.0, mean1 = 0.0;
    for (usz i = 0; i < n; i++) {
        x[i] = input[3 + 2 * i]; y[i] = input[4 + 2 * i];
        if (x[i] != x[i] || y[i] != y[i] || x[i] < -1000.0 || x[i] > 1000.0 || y[i] < -1000.0 || y[i] > 1000.0) return -1L;
        mean0 += x[i]; mean1 += y[i];
    }
    mean0 /= (double)n; mean1 /= (double)n;
    double sum0 = 0.0, sum1 = 0.0;
    for (usz i = 0; i < n; i++) { double dx = x[i] - mean0, dy = y[i] - mean1; sum0 += dx * dx; sum1 += dy * dy; }
    double denom = (double)(n - 1);
    if (sum0 <= 0.0 || sum1 <= 0.0) return -1L;
    double scale0 = sqrt(sum0 / denom), scale1 = sqrt(sum1 / denom);
    double a = 0.0, b = 0.0, d = 0.0;
    for (usz i = 0; i < n; i++) { z0[i] = (x[i] - mean0) / scale0; z1[i] = (y[i] - mean1) / scale1; a += z0[i] * z0[i]; b += z0[i] * z1[i]; d += z1[i] * z1[i]; }
    a /= denom; b /= denom; d /= denom;
    double root = sqrt((a - d) * (a - d) + 4.0 * b * b);
    double lambda0 = 0.5 * (a + d + root), lambda1 = 0.5 * (a + d - root);
    if (lambda0 - lambda1 <= 1e-8) return -1L;
    double vx, vy;
    if (b == 0.0) { vx = a >= d ? 1.0 : 0.0; vy = a >= d ? 0.0 : 1.0; }
    else { vx = b; vy = lambda0 - a; double norm = sqrt(vx * vx + vy * vy); if (norm == 0.0) return -1L; vx /= norm; vy /= norm; }
    double abs_vx = vx < 0.0 ? -vx : vx;
    double abs_vy = vy < 0.0 ? -vy : vy;
    if ((abs_vx >= abs_vy && vx < 0.0) || (abs_vy > abs_vx && vy < 0.0)) { vx = -vx; vy = -vy; }
    double[MAX_OUTPUT] staged = zeroed;
    for (usz i = 0; i < n; i++) staged[i] = z0[i] * vx + z1[i] * vy;
    staged[n] = vx; staged[n + 1] = vy; staged[n + 2] = lambda0; staged[n + 3] = lambda1;
    usz output_size = n + 4;
    if (output == null || capacity < output_size) return -2L;
    for (usz i = 0; i < output_size; i++) output[i] = staged[i];
    return (long)output_size;
}
