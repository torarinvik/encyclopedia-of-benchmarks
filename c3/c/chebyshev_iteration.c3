module chebyshev_iteration;

const usz MAX_DIMENSION = 8;
const long MAX_MATRIX_MICRO = 1000000000;
const long MAX_VECTOR_MICRO = 1000000000;
const long MAX_SPECTRAL_MICRO = 1000000000;
const long MAX_ITERATIONS = 1000;
extern fn double sqrt(double value);
extern fn void* memcpy(void* destination, void* source, usz length);

fn void write_f64_le(char* output, usz offset, double value) {
    ulong bits = 0;
    memcpy(&bits, &value, 8);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long chebyshev_iteration(long* values, usz length, char* output, usz output_capacity)
    @export("chebyshev_iteration") {
    if (values == null || length < 1 || length > 1 + MAX_DIMENSION * MAX_DIMENSION + 2 * MAX_DIMENSION + 4) return -1;
    if (values[0] < 1 || values[0] > (long)MAX_DIMENSION) return -1;
    usz n = (usz)values[0];
    if (length != 1 + n * n + 2 * n + 4) return -1;
    usz matrix_end = 1 + n * n;
    usz vector_end = matrix_end + 2 * n;
    double[MAX_DIMENSION * MAX_DIMENSION] matrix;
    double[MAX_DIMENSION] b;
    double[MAX_DIMENSION] x;
    double[MAX_DIMENSION] residual;
    double[MAX_DIMENSION] direction;
    for (usz index = 0; index < MAX_DIMENSION * MAX_DIMENSION; index++) matrix[index] = 0.0;
    for (usz index = 0; index < MAX_DIMENSION; index++) {
        b[index] = 0.0;
        x[index] = 0.0;
        residual[index] = 0.0;
        direction[index] = 0.0;
    }
    for (usz index = 0; index < n * n; index++) {
        long value = values[index + 1];
        if (value < -MAX_MATRIX_MICRO || value > MAX_MATRIX_MICRO) return -1;
        matrix[index] = (double)value / 1000000.0;
    }
    for (usz index = 0; index < n; index++) {
        long rhs = values[matrix_end + index];
        long guess = values[matrix_end + n + index];
        if (rhs < -MAX_VECTOR_MICRO || rhs > MAX_VECTOR_MICRO ||
            guess < -MAX_VECTOR_MICRO || guess > MAX_VECTOR_MICRO) return -1;
        b[index] = (double)rhs / 1000000.0;
        x[index] = (double)guess / 1000000.0;
    }
    long min_micro = values[vector_end];
    long max_micro = values[vector_end + 1];
    long iterations = values[vector_end + 2];
    long tolerance_micro = values[vector_end + 3];
    if (min_micro < 1 || max_micro <= min_micro || max_micro > MAX_SPECTRAL_MICRO ||
        iterations < 1 || iterations > MAX_ITERATIONS ||
        tolerance_micro < 1 || tolerance_micro > MAX_VECTOR_MICRO) return -1;
    double min_eigenvalue = (double)min_micro / 1000000.0;
    double max_eigenvalue = (double)max_micro / 1000000.0;
    double tolerance = (double)tolerance_micro / 1000000.0;
    usz output_bytes = n * 8;
    if (output == null || output_capacity < output_bytes) return -2;

    for (usz row = 0; row < n; row++) {
        double product = 0.0;
        for (usz column = 0; column < n; column++) product += matrix[row * n + column] * x[column];
        residual[row] = b[row] - product;
    }
    double d = (max_eigenvalue + min_eigenvalue) / 2.0;
    double c = (max_eigenvalue - min_eigenvalue) / 2.0;
    double alpha = 0.0;
    double alpha_previous = 0.0;
    for (long iteration = 0; iteration < iterations; iteration++) {
        double squares = 0.0;
        for (usz index = 0; index < n; index++) squares += residual[index] * residual[index];
        if (sqrt(squares) < tolerance) break;
        if (iteration == 0) {
            alpha = 1.0 / d;
            for (usz index = 0; index < n; index++) direction[index] = residual[index];
        } else {
            double half_step = c * alpha_previous / 2.0;
            double beta = half_step * half_step;
            alpha = 1.0 / (d - beta / alpha_previous);
            double direction_scale = beta / alpha_previous;
            for (usz index = 0; index < n; index++) direction[index] = residual[index] + direction_scale * direction[index];
        }
        for (usz index = 0; index < n; index++) x[index] += alpha * direction[index];
        for (usz row = 0; row < n; row++) {
            double product = 0.0;
            for (usz column = 0; column < n; column++) product += matrix[row * n + column] * x[column];
            residual[row] = b[row] - product;
        }
        alpha_previous = alpha;
    }
    for (usz index = 0; index < n; index++) write_f64_le(output, index * 8, x[index]);
    return (long)output_bytes;
}
