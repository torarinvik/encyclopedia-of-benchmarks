module cholesky_decomposition;

const usz MAX_DIMENSION = 6;
const long MAX_ENTRY_MICRO = 1000000000;
extern fn double sqrt(double value);
extern fn double fabs(double value);

fn void write_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long cholesky_decomposition(long* values, usz length, char* output, usz output_capacity)
    @export("cholesky_decomposition") {
    if (values == null || length < 1 || values[0] < 1 || values[0] > (long)MAX_DIMENSION) return -1;
    usz n = (usz)values[0];
    if (length != 1 + n * n) return -1;

    double[MAX_DIMENSION * MAX_DIMENSION] matrix = zeroed;
    double[MAX_DIMENSION * MAX_DIMENSION] lower = zeroed;
    for (usz index = 0; index < n * n; index++) {
        long scaled = values[index + 1];
        if (scaled < -MAX_ENTRY_MICRO || scaled > MAX_ENTRY_MICRO) return -1;
        matrix[index] = (double)scaled / 1000000.0;
    }
    for (usz row = 0; row < n; row++) {
        for (usz column = 0; column < n; column++) {
            double left = matrix[row * n + column];
            double right = matrix[column * n + row];
            if (fabs(left - right) > 1.0e-8 + 1.0e-5 * fabs(right)) return -1;
        }
    }

    for (usz row = 0; row < n; row++) {
        for (usz column = 0; column <= row; column++) {
            double sum = 0.0;
            for (usz index = 0; index < column; index++)
                sum += lower[row * n + index] * lower[column * n + index];
            double residual = matrix[row * n + column] - sum;
            if (row == column) {
                if (residual <= 0.0) return -1;
                lower[row * n + column] = sqrt(residual);
            } else {
                lower[row * n + column] = residual / lower[column * n + column];
            }
        }
    }

    usz output_bytes = n * n * 8;
    if (output_bytes > output_capacity || output == null) return -2;
    for (usz index = 0; index < n * n; index++) write_f64_le(output, index * 8, lower[index]);
    return (long)output_bytes;
}
