module spectral_norm;

extern fn double sqrt(double value);
const usz MAX_DIMENSION = 64;
const double INVALID_RESULT = -1e300;

fn double matrix_entry(usz i, usz j) {
    usz triangular = (i + j) * (i + j + 1) / 2;
    return 1.0 / (double)(triangular + i + 1);
}

fn void multiply_a(usz n, double* input, double* output) {
    for (usz i = 0; i < n; i++) {
        double total = 0.0;
        for (usz j = 0; j < n; j++) total += matrix_entry(i, j) * input[j];
        output[i] = total;
    }
}

fn void multiply_at(usz n, double* input, double* output) {
    for (usz i = 0; i < n; i++) {
        double total = 0.0;
        for (usz j = 0; j < n; j++) total += matrix_entry(j, i) * input[j];
        output[i] = total;
    }
}

fn void multiply_ata(usz n, double* input, double* output, double* temporary) {
    multiply_a(n, input, temporary);
    multiply_at(n, temporary, output);
}

fn double spectral_norm(long* values, ulong length) @export("spectral_norm") {
    if (values == null || length != 1 || values[0] < 1 || values[0] > (long)MAX_DIMENSION)
        return INVALID_RESULT;
    usz n = (usz)values[0];
    double[MAX_DIMENSION] u = {};
    double[MAX_DIMENSION] v = {};
    double[MAX_DIMENSION] temporary = {};
    for (usz i = 0; i < n; i++) u[i] = 1.0;
    for (usz iteration = 0; iteration < 10; iteration++) {
        multiply_ata(n, &u[0], &v[0], &temporary[0]);
        multiply_ata(n, &v[0], &u[0], &temporary[0]);
    }
    double v_b_v = 0.0, v_v = 0.0;
    for (usz i = 0; i < n; i++) {
        v_b_v += u[i] * v[i];
        v_v += v[i] * v[i];
    }
    return sqrt(v_b_v / v_v);
}
