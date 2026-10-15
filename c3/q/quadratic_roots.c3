module quadratic_roots;

extern fn double sqrt(double value);

const long COEFFICIENT_LIMIT = 1000000;

fn void write_f64_le(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long quadratic_roots(long* values, usz length, char* output, usz output_capacity)
    @export("quadratic_roots") {
    if (values == null || length != 3) return -1;
    long ai = values[0], bi = values[1], ci = values[2];
    if (ai == 0 || ai < -COEFFICIENT_LIMIT || ai > COEFFICIENT_LIMIT ||
        bi < -COEFFICIENT_LIMIT || bi > COEFFICIENT_LIMIT ||
        ci < -COEFFICIENT_LIMIT || ci > COEFFICIENT_LIMIT) return -1;

    double a = (double)ai, b = (double)bi, c = (double)ci;
    double discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0) return 0;

    if (discriminant == 0.0) {
        if (output == null || output_capacity < 8) return -2;
        write_f64_le(-b / (2.0 * a), output, 0);
        return 1;
    }

    if (output == null || output_capacity < 16) return -2;
    double square_root = sqrt(discriminant);
    write_f64_le((-b + square_root) / (2.0 * a), output, 0);
    write_f64_le((-b - square_root) / (2.0 * a), output, 8);
    return 2;
}

