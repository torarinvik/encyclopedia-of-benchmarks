module rayleigh_quotient;

extern fn double floor(double value);

fn long rayleigh_quotient(double* values, usz length,
                          double* output, usz capacity) @export("rayleigh_quotient") {
    if (values == null || length < 1 || length > 273) return -1;
    for (usz i = 0; i < length; i++) {
        if (values[i] != values[i]) return -1;
    }
    double n_value = values[0];
    if (n_value < 1.0 || n_value > 16.0 || floor(n_value) != n_value) return -1;
    usz n = (usz)n_value;
    if (length != 1 + n * n + n) return -1;
    double* matrix = values + 1;
    double* vector = matrix + n * n;
    for (usz i = 0; i < n * n; i++)
        if (matrix[i] < -1000.0 || matrix[i] > 1000.0) return -1;
    for (usz row = 0; row < n; row++)
        for (usz col = row + 1; col < n; col++)
            if (matrix[row * n + col] != matrix[col * n + row]) return -1;

    double denominator = 0.0;
    for (usz i = 0; i < n; i++) {
        if (vector[i] < -100.0 || vector[i] > 100.0) return -1;
        denominator += vector[i] * vector[i];
    }
    if (denominator <= 0.0) return -1;

    double numerator = 0.0;
    for (usz col = 0; col < n; col++) {
        double v_star_dot = 0.0;
        for (usz row = 0; row < n; row++)
            v_star_dot += vector[row] * matrix[row * n + col];
        numerator += v_star_dot * vector[col];
    }
    double quotient = numerator / denominator;
    if (output == null || capacity < 1) return -2;
    output[0] = quotient;
    return 1;
}
