module parboil_stencil_laplacian;

const long MAX_CELLS = 125;

fn long parboil_stencil_laplacian(double* input, usz length,
                                  double* output, usz capacity)
    @export("parboil_stencil_laplacian") {
    if (input == null || length < 4 || length > 129) return -1;
    for (usz h = 0; h < 4; h++) if (input[h] != input[h]) return -1;
    if (input[0] < 3 || input[0] > 5 || input[1] < 3 || input[1] > 5 ||
        input[2] < 3 || input[2] > 5 || input[3] < 1 || input[3] > 4) return -1;
    for (usz h = 0; h < 4; h++) if (input[h] != (double)(long)input[h]) return -1;
    usz nx = (usz)input[0], ny = (usz)input[1], nz = (usz)input[2];
    usz steps = (usz)input[3], cells = nx * ny * nz;
    if (length != 4 + cells) return -1;
    for (usz q = 0; q < cells; q++) {
        double value = input[4 + q];
        if (value != value || value < -8.0 || value > 8.0) return -1;
    }
    if (output == null || capacity < cells) return -2;

    float a[MAX_CELLS] = {0.0}, b[MAX_CELLS] = {0.0};
    double staged[MAX_CELLS] = {0.0};
    for (usz q = 0; q < cells; q++) a[q] = b[q] = (float)input[4 + q];
    float c0 = 1.0f / 6.0f, c1 = (1.0f / 6.0f) / 6.0f;
    for (usz step = 0; step < steps; step++) {
        for (usz i = 1; i + 1 < nx; i++) for (usz j = 1; j + 1 < ny; j++) for (usz k = 1; k + 1 < nz; k++) {
            usz q = i + nx * (j + ny * k);
            float sum = a[q + nx * ny] + a[q - nx * ny];
            sum = sum + a[q + nx]; sum = sum + a[q - nx];
            sum = sum + a[q + 1]; sum = sum + a[q - 1];
            float neighbor_term = sum * c1;
            float center_term = a[q] * c0;
            b[q] = neighbor_term - center_term;
        }
        for (usz q = 0; q < cells; q++) { float temp = a[q]; a[q] = b[q]; b[q] = temp; }
    }
    for (usz q = 0; q < cells; q++) staged[q] = (double)a[q];
    for (usz q = 0; q < cells; q++) output[q] = staged[q];
    return (long)cells;
}
